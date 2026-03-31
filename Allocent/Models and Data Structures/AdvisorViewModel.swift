//
//  AdvisorViewModel.swift
//  Allocent
//
//  Created by Valerie on 3/29/26.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FoundationModels

@MainActor
@Observable
final class AdvisorViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var isModelAvailable: Bool = false

    private var session: LanguageModelSession?
    private let db = Firestore.firestore()

    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }


    func setup() async {
        //can't be tested on simulator. must use physical device
        #if targetEnvironment(simulator)
        isModelAvailable = false
        messages.append(ChatMessage(
            role: .system,
            content: "The budget advisor uses Apple Intelligence, which is not available in the Simulator. Please run on a physical device to use this feature."
        ))
        return
        #else
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            isModelAvailable = true
        case .unavailable(.appleIntelligenceNotEnabled):
            //apple intelligence available on phone, but not enabled by user. user must enable and then may have to wait a few mins until things like playground finish downloading
            isModelAvailable = false
            messages.append(ChatMessage(
                role: .system,
                content: "Please enable Apple Intelligence in Settings to use the budget advisor."
            ))
            return
        case .unavailable:
            //if on a device that isn't equipped with apple intelligence :(
            isModelAvailable = false
            messages.append(ChatMessage(
                role: .system,
                content: "Apple Intelligence is not available on this device. The budget advisor requires a compatible device running iOS 26 or later."
            ))
            return
        }
        #endif

        let instructions = await buildSystemInstructions()
        session = LanguageModelSession(instructions: instructions)

        //first message from bot.
        //TODO: this is an issue bc keeps "sending" the message everytime click back to advisor tab.
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hi! I've loaded your budget data for this month. You can ask me things like \"How much do I have left for food?\" or \"Which categories am I spending the most in?\""
        ))
    }


    //AI response
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let session else { return }

        messages.append(ChatMessage(role: .user, content: text))
        inputText = ""
        isLoading = true

        do {
            let response = try await session.respond(to: text)
            messages.append(ChatMessage(role: .assistant, content: response.content))
        } catch let error as LanguageModelSession.GenerationError {
            handleGenerationError(error)
        } catch {
            messages.append(ChatMessage(
                role: .system,
                content: "Something went wrong. Please try again."
            ))
        }

        isLoading = false
    }

    //if errors
    func resetSession() async {
        messages.removeAll()
        session = nil
        await setup()
    }

    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) {
        switch error {
        case .exceededContextWindowSize:
            messages.append(ChatMessage(
                role: .system,
                content: "Our conversation got too long. Starting a fresh session..."
            ))
            Task { await resetSession() }
        default:
            messages.append(ChatMessage(
                role: .system,
                content: "Something went wrong: \(error.localizedDescription)"
            ))
        }
    }

    //instructions/skills for AI chatbot
    private func buildSystemInstructions() async -> String {
        //will have all the instructions/specifications/context for the bot
        var parts: [String] = []

        parts.append("""
            You are a helpful assistant inside a personal budgeting app called Allocent. \
            Your role is to help the user understand and organize their own budget data shown below. \
            You can summarize their spending, compare categories, point out which categories \
            have room left, and suggest everyday ways to stay within their budget. \
            You are NOT a financial advisor. Do not recommend investments, credit products, or \
            financial services. Just help them make sense of their own numbers. \
            Keep responses short (2-4 sentences) unless the user asks for more detail. \
            Be encouraging and practical.
            """)

        guard let uid else {
            parts.append("No user data is available.")
            return parts.joined(separator: "\n\n")
        }

        //TODO: once expenses and budget functionality complete, need to make sure fields in firestore are named correctly and this part below actually works as context
        //at this point, user could be real user w uid but just not have expenses/budget data
        
        //get the user's budget categories
        var categories: [BudgetCategory] = []
        if let snap = try? await db.collection("users").document(uid)
            .collection("categories").getDocuments() {
            categories = snap.documents.map { doc in
                let data = doc.data()
                return BudgetCategory(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    limit: data["limit"] as? Double ?? 0,
                    colorHex: data["colorHex"] as? String
                )
            }
        }

        //get user expenses for curr month
        var spentByCategory: [String: Double] = [:]
        if let snap = try? await db.collection("users").document(uid)
            .collection("expenses")
            .whereField("month", isEqualTo: currentMonth)
            .getDocuments() {
            for doc in snap.documents {
                let data = doc.data()
                let catId = data["categoryId"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0
                spentByCategory[catId, default: 0] += amount
            }
        }

        //get user income sources
        var incomeSources: [IncomeSource] = []
        if let snap = try? await db.collection("users").document(uid)
            .collection("income_sources").getDocuments() {
            incomeSources = snap.documents.map { doc in
                let data = doc.data()
                return IncomeSource(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    amount: data["amount"] as? Double ?? 0,
                    dateAdded: nil
                )
            }
        }

        let totalIncome = incomeSources.reduce(0) { $0 + $1.amount }
        let totalBudget = categories.reduce(0) { $0 + $1.limit }
        let totalSpent = spentByCategory.values.reduce(0, +)
        let safeToSpend = max(totalBudget - totalSpent, 0)

        parts.append("--- USER'S BUDGET DATA (Current Month: \(currentMonth)) ---")

        if !incomeSources.isEmpty {
            let lines = incomeSources.map { "  - \($0.name): $\(String(format: "%.2f", $0.amount))" }
            parts.append("Income Sources:\n\(lines.joined(separator: "\n"))\nTotal Monthly Income: $\(String(format: "%.2f", totalIncome))")
        } else {
            parts.append("Income: No income sources set up yet.")
        }

        if !categories.isEmpty {
            var lines: [String] = []
            for cat in categories.sorted(by: { $0.name < $1.name }) {
                let spent = spentByCategory[cat.id, default: 0]
                let left = max(cat.limit - spent, 0)
                let pct = cat.limit > 0 ? (spent / cat.limit) * 100 : 0
                lines.append("  - \(cat.name): Budget $\(String(format: "%.2f", cat.limit)), Spent $\(String(format: "%.2f", spent)), Remaining $\(String(format: "%.2f", left)) (\(String(format: "%.0f", pct))% used)")
            }
            parts.append("Budget Categories:\n\(lines.joined(separator: "\n"))")
        } else {
            parts.append("Budget Categories: None set up yet.")
        }

        parts.append("""
            Summary:
              Total Budget: $\(String(format: "%.2f", totalBudget))
              Total Spent: $\(String(format: "%.2f", totalSpent))
              Safe to Spend: $\(String(format: "%.2f", safeToSpend))
            """)

        return parts.joined(separator: "\n\n")
    }
}

//
//  OnboardingViewModel.swift
//  Allocent
//
//  Created by Valerie on 4/7/26.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    enum Step: Int, CaseIterable {
        case welcome = 0
        case income = 1
        case categorySelection = 2
        case budgetCategories = 3
        case bankLink = 4
        case completion = 5
    }

    @Published var currentStep: Step = .welcome

    @Published var incomeSources: [DraftIncome] = []
    @Published var newIncomeName: String = ""
    @Published var newIncomeAmount: Double?

    @Published var selectedCategories: Set<TransactionCategory> = []

    @Published var categoryAllocations: [TransactionCategory: Double] = {
        var defaults: [TransactionCategory: Double] = [:]
        for category in TransactionCategory.allCases {
            defaults[category] = 0
        }
        return defaults
    }()

    var totalAllocated: Double {
        selectedCategories.reduce(0) { $0 + (categoryAllocations[$1] ?? 0) }
    }

    var isOverAllocated: Bool {
        totalAllocated > totalIncome
    }

    func updateAllocation(for category: TransactionCategory, amount: Double) {
        categoryAllocations[category] = max(amount, 0)
    }

    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    struct PlaidSessionLink: Identifiable {
        let id: String
        let institution: String?
    }

    @Published private(set) var plaidLinksThisSession: [PlaidSessionLink] = []

    func registerPlaidLink(itemId: String, institution: String?) {
        plaidLinksThisSession.append(PlaidSessionLink(id: itemId, institution: institution))
    }

    struct DraftIncome: Identifiable {
        let id = UUID()
        var name: String
        var amount: Double
    }

    var totalIncome: Double {
        incomeSources.reduce(0) { $0 + $1.amount }
    }

    var canProceedFromIncome: Bool {
        !incomeSources.isEmpty
    }

    var canAddIncome: Bool {
        let trimmed = newIncomeName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && (newIncomeAmount ?? 0) > 0
    }

    var isBudgetFullyAllocated: Bool {
        guard totalIncome > 0 else { return false }
        let selectedTotal = selectedCategories.reduce(0) { $0 + (categoryAllocations[$1] ?? 0) }
        return selectedTotal == totalIncome
    }

    var stepCount: Int {
        Step.allCases.count
    }

    func goToNext() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }

    func goToPrevious() {
        guard let prev = Step(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prev
        }
    }

    func addIncome() {
        let trimmed = newIncomeName.trimmingCharacters(in: .whitespaces)
        guard let amount = newIncomeAmount, amount > 0, !trimmed.isEmpty else { return }
        incomeSources.append(DraftIncome(name: trimmed, amount: amount))
        newIncomeName = ""
        newIncomeAmount = nil
    }

    func removeIncome(id: UUID) {
        incomeSources.removeAll { $0.id == id }
    }

    func saveAllData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "OnboardingViewModel", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        do {
            let batch = db.batch()

            // write income sources
            for source in incomeSources {
                let ref = userRef.collection("income_sources").document()
                batch.setData([
                    "name": source.name,
                    "amount": source.amount,
                    "dateAdded": FieldValue.serverTimestamp()
                ], forDocument: ref)
            }

            // write only selected categories using rawValue as document ID
            for category in selectedCategories {
                let ref = userRef.collection("categories").document(category.rawValue)
                let limit = categoryAllocations[category] ?? 0
                batch.setData([
                    "name": category.rawValue,
                    "limit": limit
                ], forDocument: ref)
            }

            // save visibleCategories array to user document
            batch.setData([
                "visibleCategories": selectedCategories.map { $0.rawValue }
            ], forDocument: userRef, merge: true)

            try await batch.commit()

            let monthKey = ExpenseCategoryAllocationService.currentMonthKey()
            try await ExpenseCategoryAllocationService.allocateCategoryIdsForMonth(monthKey)

            isSaving = false
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}

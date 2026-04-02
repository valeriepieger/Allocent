//
//  TransactionCategory.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//


import Foundation
import SwiftData

enum TransactionCategory: String, Codable, CaseIterable {
    case food = "Food & Drink"
    case transport = "Transport"
    case groceries = "Groceries"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case health = "Health"
    case utilities = "Utilities"
    case other = "Other"

    var emoji: String {
        switch self {
        case .food: return "🍔"
        case .transport: return "🚗"
        case .groceries: return "🛒"
        case .shopping: return "🛍️"
        case .entertainment: return "🎬"
        case .health: return "💊"
        case .utilities: return "💡"
        case .other: return "📦"
        }
    }

    var color: String {
        switch self {
        case .food: return "orange"
        case .transport: return "blue"
        case .groceries: return "green"
        case .shopping: return "pink"
        case .entertainment: return "purple"
        case .health: return "red"
        case .utilities: return "yellow"
        case .other: return "gray"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var merchant: String
    var amount: Double
    var date: Date
    var category: TransactionCategory
    var notes: String

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Double,
        date: Date = .now,
        category: TransactionCategory = .other,
        notes: String = ""
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.category = category
        self.notes = notes
    }
}

extension Transaction {
    static var sampleTransactions: [Transaction] {
        let cal = Calendar.current
        let today = Date.now
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!
        let lastWeek = cal.date(byAdding: .day, value: -6, to: today)!

        return [
            Transaction(merchant: "Starbucks", amount: 7.45, date: today, category: .food),
            Transaction(merchant: "Uber", amount: 14.20, date: today, category: .transport),
            Transaction(merchant: "Chipotle", amount: 13.85, date: yesterday, category: .food),
            Transaction(merchant: "Whole Foods", amount: 87.32, date: yesterday, category: .groceries),
            Transaction(merchant: "Netflix", amount: 15.99, date: twoDaysAgo, category: .entertainment),
            Transaction(merchant: "CVS Pharmacy", amount: 24.60, date: twoDaysAgo, category: .health),
            Transaction(merchant: "Apple Store", amount: 49.99, date: lastWeek, category: .shopping),
            Transaction(merchant: "Shell Gas Station", amount: 62.10, date: lastWeek, category: .transport),
            Transaction(merchant: "Spotify", amount: 9.99, date: lastWeek, category: .entertainment),
            Transaction(merchant: "HEB Grocery", amount: 112.47, date: lastWeek, category: .groceries),
        ]
    }
}

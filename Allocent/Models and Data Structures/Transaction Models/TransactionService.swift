//
//  TransactionService.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct TransactionService {

    private static func expensesCollection() throws -> CollectionReference {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw TransactionServiceError.notAuthenticated
        }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("expenses")
    }

    /// Save a scanned receipt as an expense document
    static func add(_ transaction: Transaction) async throws {
        try await expensesCollection().addDocument(data: transaction.toExpenseData())
    }

    /// Delete an expense by ID
    static func delete(_ transaction: Transaction) async throws {
        try await expensesCollection().document(transaction.id).delete()
    }

    /// Fetch all expenses as Transactions for the list view
    static func fetch() async throws -> [Transaction] {
        let snapshot = try await expensesCollection()
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { Transaction.from($0) }
    }
}

enum TransactionServiceError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? { "You must be signed in to access transactions." }
}

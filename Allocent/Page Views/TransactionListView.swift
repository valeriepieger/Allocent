//
//  TransactionListView.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showAddManual = false
    @State private var showScanReceipt = false
    @State private var searchText = ""
    @State private var service = ExpenseService()

    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else { return transactions }
        return transactions.filter {
            $0.merchant.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedTransactions: [(String, [Transaction])] {
        service.groupedByDate(filteredTransactions)
    }

    private var totalSpend: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionList
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showScanReceipt = true
                        } label: {
                            Label("Scan Receipt", systemImage: "camera")
                        }

                        Button {
                            showAddManual = true
                        } label: {
                            Label("Enter Manually", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddManual) {
                AddTransactionView()
            }
            .sheet(isPresented: $showScanReceipt) {
                ScanReceiptView()
            }
            .task {
                try? service.seedSampleData(modelContext: modelContext)
            }
        }
    }

    // subviews

    private var transactionList: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Spent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(totalSpend, format: .currency(code: "USD"))
                            .font(.title.bold())
                    }
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tint)
                }
                .padding(.vertical, 4)
            }

            ForEach(groupedTransactions, id: \.0) { label, dayTransactions in
                Section(label) {
                    ForEach(dayTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    try? service.delete(transaction: transaction, modelContext: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No Transactions Yet")
                .font(.title3.bold())
            Text("Scan a receipt or add one manually to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 12) {
                Button {
                    showScanReceipt = true
                } label: {
                    Label("Scan", systemImage: "camera")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showAddManual = true
                } label: {
                    Label("Manual", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
    }
}

// transaction row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 44, height: 44)
                Text(transaction.category.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant)
                    .font(.body)
                    .fontWeight(.medium)
                Text(transaction.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount, format: .currency(code: "USD"))
                    .font(.body.weight(.semibold))
                Text(transaction.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

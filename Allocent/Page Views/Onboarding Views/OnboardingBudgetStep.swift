//
//  OnboardingBudgetStep.swift
//  Allocent
//
//  Created by Valerie on 4/9/26.
//

import SwiftUI

struct OnboardingBudgetStep: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderWithSubtitle(
                title: "Budget Categories",
                subtitle: "Set a monthly budget for your selected categories"
            )
            .padding(.horizontal, 24)

            IncomeSummaryHeader(
                totalIncome: viewModel.totalIncome,
                totalAllocated: viewModel.totalAllocated,
                isOverAllocated: viewModel.isOverAllocated
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.selectedCategories).sorted { $0.rawValue < $1.rawValue }, id: \.self) { category in
                        BudgetCategoryRow(
                            category: category,
                            amount: Binding(
                                get: { viewModel.categoryAllocations[category] ?? 0 },
                                set: { viewModel.updateAllocation(for: category, amount: $0) }
                            ),
                            isSelected: true
                        )
                    }

                    let unselected = TransactionCategory.allCases.filter { !viewModel.selectedCategories.contains($0) }
                    if !unselected.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Not selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            ForEach(unselected.sorted { $0.rawValue < $1.rawValue }, id: \.self) { category in
                                BudgetCategoryRow(
                                    category: category,
                                    amount: .constant(0),
                                    isSelected: false
                                )
                            }
                        }
                    }

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)

            OnboardingBudgetBottomNav()
        }
    }
}

private struct IncomeSummaryHeader: View {
    let totalIncome: Double
    let totalAllocated: Double
    let isOverAllocated: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Income")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(totalIncome, format: .currency(code: "USD"))
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Allocated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(totalAllocated, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(isOverAllocated ? .red : Color("OliveGreen"))
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
    }
}

private struct BudgetCategoryRow: View {
    let category: TransactionCategory
    @Binding var amount: Double
    let isSelected: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundStyle(isSelected ? Color("OliveGreen") : Color.gray.opacity(0.4))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                if isSelected {
                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .frame(width: 80)
                        Text("/mo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Not selected")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if !isSelected {
                Image(systemName: "minus.circle")
                    .foregroundStyle(Color.gray.opacity(0.3))
            }
        }
        .padding()
        .background(isSelected ? Color("CardBackground") : Color("CardBackground").opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: isSelected ? Color.black.opacity(0.05) : Color.clear, radius: 4, x: 0, y: 2)
        .opacity(isSelected ? 1 : 0.5)
    }
}

private struct OnboardingBudgetBottomNav: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    private var remaining: Double {
        viewModel.totalIncome - viewModel.totalAllocated
    }

    var body: some View {
        VStack(spacing: 8) {
            if !viewModel.isBudgetFullyAllocated && viewModel.totalIncome > 0 {
                Text(remaining > 0
                     ? "$\(remaining, specifier: "%.2f") left to allocate"
                     : "Over-allocated by $\(abs(remaining), specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(remaining > 0 ? Color.secondary : Color.red)
            }

            HStack(spacing: 12) {
                Button(action: viewModel.goToPrevious) {
                    Text("Back")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color("CardBackground"))
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.primary.opacity(0.08), lineWidth: 1)
                        )
                }

                PrimaryActionButton(
                    title: "Next",
                    disabled: !viewModel.isBudgetFullyAllocated
                ) {
                    viewModel.goToNext()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

#Preview {
    OnboardingBudgetStep()
        .environmentObject(OnboardingViewModel())
}

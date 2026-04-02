//
//  EditCategoriesView.swift
//  BudgetApp
//
//  Created by Valerie on 2/23/26.
//

import SwiftUI

private func parseCategoryNumeric(_ text: String) -> Double? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return Double(trimmed.replacingOccurrences(of: ",", with: "."))
}

struct EditCategoriesView: View {
    @StateObject private var viewModel = EditCategoriesViewModel()
    @State private var hasAppeared = false
    @State private var showAddCategory = false
    @AppStorage("allocent.categories.usePercentage") private var usePercentageAllocation = false
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack {
                HeaderWithBack(pageName: "Edit Categories")
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Left to Budget")
                            .foregroundColor(.gray)
                        Text("$\(viewModel.leftToBudget, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(viewModel.allocationPercentText)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Allocation method")
                            .font(.headline)
                        HStack {
                            Text("Dollars")
                                .font(.subheadline.weight(usePercentageAllocation ? .regular : .semibold))
                                .foregroundColor(usePercentageAllocation ? .gray : .primary)
                            Spacer()
                            Toggle("", isOn: $usePercentageAllocation)
                                .labelsHidden()
                                .tint(Color("OliveGreen"))
                            Spacer()
                            Text("% of income")
                                .font(.subheadline.weight(usePercentageAllocation ? .semibold : .regular))
                                .foregroundColor(usePercentageAllocation ? .primary : .gray)
                        }
                        Text(usePercentageAllocation
                             ? "Set each category as a percent of your total monthly income. Limits are saved as dollars."
                             : "Set each category limit in dollars.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Categories")
                            .font(.headline)
                        Spacer()
                        Button(action: { showAddCategory = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color("OliveGreen"))
                        }
                    }
                    
                    ScrollView {
                        if viewModel.categories.isEmpty {
                            Text("No categories yet. Tap Add to create one.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    EditCategoryRow(
                                        category: category,
                                        totalIncome: viewModel.totalIncome,
                                        usePercentageAllocation: usePercentageAllocation,
                                        onSave: { name, limit in
                                            Task { await viewModel.updateCategory(id: category.id, name: name, limit: limit) }
                                        },
                                        onDelete: {
                                            Task { await viewModel.deleteCategory(id: category.id) }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(viewModel: viewModel, isPresented: $showAddCategory)
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            viewModel.startListening()
        }
    }
}

private struct EditCategoryRow: View {
    let category: BudgetCategory
    let totalIncome: Double
    let usePercentageAllocation: Bool
    let onSave: (String, Double) -> Void
    let onDelete: () -> Void
    
    @State private var name: String = ""
    @State private var limitText: String = ""
    @State private var isEditing = false
    
    private var limitDollarsFromField: Double? {
        let raw = parseCategoryNumeric(limitText) ?? 0
        if usePercentageAllocation {
            guard totalIncome > 0 else { return raw == 0 ? 0 : nil }
            guard raw >= 0, raw <= 100 else { return nil }
            return totalIncome * (raw / 100)
        }
        return max(0, raw)
    }
    
    private var dollarPreview: String? {
        guard usePercentageAllocation, isEditing,
              let d = limitDollarsFromField, totalIncome > 0,
              (parseCategoryNumeric(limitText) ?? 0) > 0 else { return nil }
        return String(format: "≈ $%.2f / month", d)
    }
    
    private var percentageCaption: String {
        guard totalIncome > 0, category.limit > 0 else { return "" }
        let pct = (category.limit / totalIncome) * 100
        return String(format: "%.0f%% of income", pct)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isEditing {
                    TextField("Category name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)
                } else {
                    Text(category.name)
                        .font(.headline)
                }
                Spacer()
                Button(action: {
                    if isEditing {
                        guard let dollars = limitDollarsFromField else { return }
                        onSave(name.isEmpty ? category.name : name, dollars)
                        isEditing = false
                    } else {
                        name = category.name
                        if usePercentageAllocation, totalIncome > 0 {
                            let pct = (category.limit / totalIncome) * 100
                            limitText = String(format: "%.2f", pct)
                        } else {
                            limitText = String(format: "%.2f", category.limit)
                        }
                        isEditing = true
                    }
                }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("OliveGreen"))
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(usePercentageAllocation ? "Percent of income:" : "Monthly limit:")
                        .foregroundColor(.gray)
                    if isEditing {
                        if usePercentageAllocation {
                            HStack(spacing: 4) {
                                TextField("0", text: $limitText)
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .frame(width: 100)
                                Text("%")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Text("$")
                                TextField("0.00", text: $limitText)
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .frame(width: 100)
                            }
                        }
                    } else {
                        Text("$\(category.limit, specifier: "%.2f")")
                            .font(.subheadline.weight(.medium))
                    }
                }
                Spacer(minLength: 8)
                if !percentageCaption.isEmpty {
                    Text(percentageCaption)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if let dollarPreview {
                Text(dollarPreview)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if usePercentageAllocation && isEditing && totalIncome <= 0 {
                Text("Add income sources to budget by percentage.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .onAppear {
            name = category.name
            if usePercentageAllocation, totalIncome > 0 {
                let pct = (category.limit / totalIncome) * 100
                limitText = String(format: "%.2f", pct)
            } else {
                limitText = String(format: "%.2f", category.limit)
            }
        }
        .onChange(of: category.limit) { _, _ in
            if !isEditing {
                if usePercentageAllocation, totalIncome > 0 {
                    let pct = (category.limit / totalIncome) * 100
                    limitText = String(format: "%.2f", pct)
                } else {
                    limitText = String(format: "%.2f", category.limit)
                }
            }
        }
        .onChange(of: usePercentageAllocation) { _, newValue in
            if !isEditing {
                if newValue, totalIncome > 0 {
                    let pct = (category.limit / totalIncome) * 100
                    limitText = String(format: "%.2f", pct)
                } else {
                    limitText = String(format: "%.2f", category.limit)
                }
            }
        }
        .onChange(of: totalIncome) { _, _ in
            if !isEditing {
                if usePercentageAllocation, totalIncome > 0 {
                    let pct = (category.limit / totalIncome) * 100
                    limitText = String(format: "%.2f", pct)
                }
            }
        }
    }
}

private struct AddCategorySheet: View {
    @ObservedObject var viewModel: EditCategoriesViewModel
    @Binding var isPresented: Bool
    @AppStorage("allocent.categories.usePercentage") private var usePercentageAllocation = false
    @State private var name = ""
    @State private var limitText = ""
    @State private var isSaving = false
    
    private var dollarLimitForSave: Double? {
        let raw = parseCategoryNumeric(limitText) ?? 0
        if usePercentageAllocation {
            guard raw >= 0, raw <= 100 else { return nil }
            if raw > 0, viewModel.totalIncome <= 0 { return nil }
            return viewModel.totalIncome * (raw / 100)
        }
        guard raw >= 0 else { return nil }
        return raw
    }
    
    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return dollarLimitForSave != nil
    }
    
    private var previewDollars: String? {
        guard usePercentageAllocation,
              viewModel.totalIncome > 0,
              let p = parseCategoryNumeric(limitText), p > 0, p <= 100 else { return nil }
        let d = viewModel.totalIncome * (p / 100)
        return String(format: "≈ $%.2f / month", d)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("e.g. Food, Bills", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(usePercentageAllocation ? "Percent of income" : "Monthly limit ($)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if usePercentageAllocation {
                            HStack {
                                TextField("e.g. 10", text: $limitText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Text("%")
                                    .foregroundColor(.gray)
                            }
                            if let previewDollars {
                                Text(previewDollars)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            if viewModel.totalIncome <= 0 {
                                Text("Add income on the Income screen to use percentage allocation.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            TextField("0.00", text: $limitText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
    
    private func save() {
        guard let limit = dollarLimitForSave else { return }
        isSaving = true
        Task {
            await viewModel.addCategory(name: name.trimmingCharacters(in: .whitespaces), limit: limit)
            await MainActor.run {
                isSaving = false
                isPresented = false
            }
        }
    }
}

#Preview {
    EditCategoriesView()
}

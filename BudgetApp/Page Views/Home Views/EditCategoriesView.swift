//
//  EditCategoriesView.swift
//  BudgetApp
//
//  Created by Valerie on 2/23/26.
//

import SwiftUI

struct EditCategoriesView: View {
    @State private var isPercentageBased = true
    @State private var foodPercentage = "25"
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack {
                HeaderWithBack(categoryName: "Edit Categories")
                
                VStack(spacing: 16) {
                    
                    //"Left to Budget"
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Left to Budget")
                            .foregroundColor(.gray)
                        Text("$0.00")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("100% of 100% allocated")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    // Allocation Method Toggle
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Allocation Method")
                                .font(.headline)
                            Text(isPercentageBased ? "Percentage-based" : "Dollar-based")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("$")
                        Toggle("", isOn: $isPercentageBased)
                            .labelsHidden()
                            .tint(.oliveGreen)
                        Text("%")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    ScrollView {
                        
                        //TODO: loop through all user's saved categories instead of hardcode
                        VStack (spacing: 16) {
                            CategoriesCard(categoryName: "Food", categoryPercentage: $foodPercentage)
                            CategoriesCard(categoryName: "Bills", categoryPercentage: $foodPercentage)
                            CategoriesCard(categoryName: "Savings", categoryPercentage: $foodPercentage)
                            CategoriesCard(categoryName: "Travel", categoryPercentage: $foodPercentage)
                        }
                    }
                    
                    
                }
                .padding()
            }
        }
        }
}

#Preview {
    EditCategoriesView()
}

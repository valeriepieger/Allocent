//
//  MainTabView.swift
//  BudgetApp
//
//  Created by Valerie on 2/22/26.
//


import SwiftUI

struct AllTabsView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            DashboardView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            TransactionListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Transactions")
                }
                .tag(1)

            ExpensesView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Expenses")
                }
                .tag(2)

            Text("Advisor Chatbot View")
                .tabItem {
                    Image(systemName: "bubble.right")
                    Text("Advisor")
                }
                .tag(3)

            AccountView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Account")
                }
                .tag(4)
        }
        .tint(Color("OliveGreen"))
    }
}

#Preview {
    AllTabsView()
}

//
//  ContentView.swift
//  BudgetApp
//
//  Created by Valerie on 2/18/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            Group {
                switch session.state {
                case .loading:
                    AppCard {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Loading…")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                case .signedOut:
                    AuthLandingView()

                case .onboarding(let user):
                    OnboardingView(user: user)

                case .active:
                    NavigationStack {
                        AllTabsView()
                    }
                    .environmentObject(session)

                case .error(let message):
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Error")
                                .font(.headline)

                            Text(message)
                                .foregroundStyle(.secondary)

                            Button("Try Again") {
                                Task { await session.loadSession() }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Sign Out") {
                                session.signOut()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .environmentObject(session)
        }
        .task {
            await session.loadSession()
        }
        .onAppear {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }
}

#Preview {
    RootView()
}

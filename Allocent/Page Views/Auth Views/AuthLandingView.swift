//
//  AuthLandingView.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {

                    Text("Welcome to Allocent!")
                        .font(.largeTitle)
                        .bold()
//                        .padding(.horizontal)
                        .padding(.top, 20)
                Text("Sign in to start allocating your cents.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
//                        .padding(.bottom, 20)

                    Spacer()
                        .frame(height: 20)
                    VStack(spacing: 12) {

                        NavigationLink {
                            SignInView(session: session)
                        } label: {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundStyle(Color("PrimaryButtonText"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color("PrimaryButton"))
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SignUpView(session: session)
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color("CardBackground"))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.primary.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
        }
    }
}

#Preview {
    AuthLandingView()
        .environmentObject(SessionViewModel())
}

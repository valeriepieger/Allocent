//
//  PrimaryActionButton.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//


import SwiftUI

struct PrimaryActionButton: View {
    var title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color("PrimaryButtonText"))
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Color("PrimaryButtonText"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(disabled ? Color("PrimaryButton").opacity(0.4) : Color("PrimaryButton"))
            .cornerRadius(12)
        }
        .disabled(disabled || isLoading)
    }
}

#Preview {
    PrimaryActionButton(title: "Continue") { }
        .padding()
}
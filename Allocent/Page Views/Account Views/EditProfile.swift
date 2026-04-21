//
//  EditProfile.swift
//  BudgetApp
//
//  Created by Valerie on 2/25/26.
//

import SwiftUI

struct EditProfile: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionViewModel
    @State private var phoneNumber: String = ""
    @State private var bio: String = ""
    
    //get the user info to display
    private var currentUser: AppUser? {
        switch session.state {
        case .active(let user), .onboarding(let user):
            return user
        default:
            return nil
        }
    }

    @State private var displayFirstName: String = ""
    @State private var displayLastName: String = ""
    @State private var displayEmail: String = ""
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea(edges: .all)
            VStack {
                HeaderWithBack(pageName: "Edit Profile")
                VStack(spacing: 30) {
                    
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color("OliveGreen").opacity(Double(0.3)))
                                .frame(width: 112, height: 112)
                                .overlay(
                                    Image(systemName: "person")
                                        .font(.system(size: 36))
                                        .foregroundStyle(Color("OliveGreen"))
                                )
                            
                            //Camera Button
                            Button(action: {
                                //TODO: action to change photo
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color("OliveGreen"))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .offset(x: 4, y: 4)
                        }
                        
                        Button("Change Photo") {
                            //TODO: action to change photo
                        }
                        .font(.subheadline)
                        .foregroundColor(Color("OliveGreen"))
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 16) {
                        FormField(label: "First Name", text: $displayFirstName)
                        FormField(label: "Last Name", text: $displayLastName)
                        FormField(label: "Email", text: $displayEmail, keyboardType: .emailAddress)
                        FormField(label: "Phone Number", text: $phoneNumber, placeholder: "(555) 123-4567", keyboardType: .phonePad)
                        
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(16)
                        }
                        
                        Button(action: {
                            //TODO: add action to save changes
                        }) {
                            Text("Save Changes")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("OliveGreen"))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                
            }
        }
        .onAppear {
            displayFirstName = currentUser?.firstName ?? ""
            displayLastName = currentUser?.lastName ?? ""
            displayEmail = currentUser?.email ?? ""
        }
    }
}
        
struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color("CardBackground"))
                .cornerRadius(16)
        }
    }
}


#Preview {
    EditProfile()
}

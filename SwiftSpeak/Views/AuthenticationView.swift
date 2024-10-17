//
//  AuthenticationView.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 4/10/24.
//

import Foundation
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var showResetPassword = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                if isSignUp {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if isSignUp {
                    Button("Sign Up") {
                        authManager.signUp(email: email, password: password, name: name) { success in
                            if success {
                                print("Sign up successful")
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Button("Log In") {
                        authManager.signIn(email: email, password: password) { success in
                            if success {
                                print("Log in successful")
                            }
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                VStack {
                    Button("Login with Google") {
                        self.authManager.isSignInWithGoogle.toggle()
                        
                        Task.init {
                            await authManager.signInWithGoogle() { success in
                                if success {
                                    Message.buildLogInfo("[SUCCESS] ==> User login successfully")
                                }else {
                                    Message.buildLogError("[ERROR] ==> User login failed")
                                }
                                
                                self.authManager.isSignInWithGoogle.toggle()
                            }
                            
                            
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                }
                
                Button(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle()
                }
                .padding()
                
                if !isSignUp {
                    Button("Forgot Password?") {
                        showResetPassword = true
                    }
                    .padding()
                }
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle(isSignUp ? "Sign Up" : "Log In")
        }
        .sheet(isPresented: $showResetPassword) {
            PasswordResetView(authManager: authManager)
        }
    }
}

struct PasswordResetView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var message = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                
                Button("Reset Password") {
                    authManager.resetPassword(email: email) { success in
                        if success {
                            message = "Password reset email sent. Check your inbox."
                        } else {
                            message = authManager.errorMessage ?? "An error occurred."
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Text(message)
                    .foregroundColor(message.contains("sent") ? .green : .red)
                    .padding()
            }
            .padding()
            .navigationTitle("Reset Password")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}

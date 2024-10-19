//
//  AuthenticationView.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 4/10/24.
//

import Foundation
import SwiftUI
import RiveRuntime

struct AuthenticationView: View {
  @Environment(\.colorScheme) var systemScheme
  @StateObject private var authManager = AuthenticationManager()
  @State private var email = ""
  @State private var password = ""
  @State private var name = ""
  @State private var isSignUp = false
  @State private var isEditName = false
  @State private var isEditEmail = false
  @State private var isEditPassword = false
  @State private var isIconNameBounce = false
  @State private var isIconEmailBounce = false
  @State private var isIconPasswordBounce = false
  @State private var showResetPassword = false
  
  
  var body: some View {
    NavigationView {
      ZStack {
        if systemScheme == .dark {
          Image("Shiny Background")
            .resizable()
            .blur(radius: 16)
          
            .ignoresSafeArea()
        }else {
          RiveViewModel(fileName: "shapes_2").view()
            .ignoresSafeArea()
            .blur(radius: 50)
            .background(
              Image("Spline")
                .resizable()
                .blur(radius: 50)
                .offset(x: 100, y: 200)
            )
        }
        VStack {
          Text(isSignUp ? "Sign Up" : "Sign In")
            .font(.custom("Poppins-Bold", size: 40))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(LinearGradient(colors: [Color("Pink Gradient 1"), Color("Pink Gradient 2")], startPoint: .topLeading, endPoint: .bottomTrailing))
          
          Text(isSignUp ? "Create Your Account with Ease" : "Secure and Smooth Recording Experience")
            .font(.custom("Poppins-Bold", size: 30))
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(3)
          if isSignUp {
            TextField("Name", text: $name)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding(.horizontal)
          }
          
          GradientTextField(
            textFieldPlaceholder: "Email",
            textFieldIconString: "envelope.open.fill",
            isPassword: false,
            isCurrentlyEditingTextField: $isEditEmail,
            textFieldInputString: $email,
            iconBounce: $isIconEmailBounce )
          .shadow(color: Color(hex: "8352F5"),
                  radius: isEditEmail ? 12.0 : 50.0, x: 0, y: 0)
          
          GradientTextField(
            textFieldPlaceholder: "Password",
            textFieldIconString: "key.fill",
            isPassword: true,
            isCurrentlyEditingTextField: $isEditPassword,
            textFieldInputString: $password,
            iconBounce: $isIconPasswordBounce)
          .shadow(color: Color(hex: "8352F5"), radius: isEditPassword ? 12.0 : 50.0, x: 0, y: 0)
          
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
      }
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




//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 100, height: 100)
//                    .foregroundColor(.blue)
//                    .padding(.bottom, 20)

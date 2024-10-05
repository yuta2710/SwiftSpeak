//
//  AuthenticationManager.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 4/10/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FacebookLogin

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isSignInEnabled = true
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
    }
    
    func registerAuthStateHandler() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.isSignInEnabled = user == nil
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        guard isSignInEnabled else {
            errorMessage = "Please log out before creating a new account."
            completion(false)
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            guard let user = authResult?.user else {
                self?.errorMessage = "Failed to create user."
                completion(false)
                return
            }
            
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "createdAt": Timestamp(date: Date())
            ]
            
            Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self?.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    completion(false)
                } else {
                    self?.isAuthenticated = true
                    self?.isSignInEnabled = false
                    completion(true)
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        guard isSignInEnabled else {
            errorMessage = "Please log out before signing in to another account."
            completion(false)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(false)
            } else {
                self?.isAuthenticated = true
                self?.isSignInEnabled = false
                completion(true)
            }
        }
    }
    
    func signInWithFacebook() {
        guard isSignInEnabled else {
            errorMessage = "Please log out before signing in with Facebook."
            return
        }
        
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] (result, error) in
            if let error = error {
                self?.errorMessage = "Facebook login failed: \(error.localizedDescription)"
                return
            }
            
            guard let accessToken = AccessToken.current else {
                self?.errorMessage = "Failed to get access token"
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                if let error = error {
                    self?.errorMessage = "Firebase auth failed: \(error.localizedDescription)"
                } else {
                    self?.isAuthenticated = true
                    self?.isSignInEnabled = false
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.isSignInEnabled = true
        } catch let error {
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

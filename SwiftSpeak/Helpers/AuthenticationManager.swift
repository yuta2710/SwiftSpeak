//
//  AuthenticationManager.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 4/10/24.
//

import FacebookLogin
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import GoogleSignIn

class AuthenticationManager: ObservableObject {
	@Published var user: User?
	@Published var isAuthenticated = false
	@Published var errorMessage: String?
	@Published var signInEnable = true

	@Published var isSignInWithGoogle: Bool = false
	@Published var userProfile: UserProfile? = nil

	private var handle: AuthStateDidChangeListenerHandle?
	private let db = Firestore.firestore()

	var isActive: Bool {
		return Auth.auth().currentUser != nil
	}

	init() {
		registerAuthStateHandler()
		Task.init {
			try await loadCurrentUserProfile()
		}
	}

	func registerAuthStateHandler() {
		if let handle = handle {
			Auth.auth().removeStateDidChangeListener(handle)
		}

		handle = Auth.auth().addStateDidChangeListener {
			[weak self] (_, user) in
			DispatchQueue.main.async {
				self?.user = user
				self?.isAuthenticated = user != nil
			}
		}
	}

	func signUp(
		email: String, password: String, name: String,
		completion: @escaping (Bool) -> Void
	) {
		Auth.auth().createUser(withEmail: email, password: password) {
			[weak self] authResult, error in
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
				"createdAt": Timestamp(date: Date()),
			]

			Firestore.firestore().collection("users").document(user.uid)
				.setData(userData) { error in
					if let error = error {
						self?.errorMessage =
							"Failed to save user data: \(error.localizedDescription)"
						completion(false)
					} else {
						self?.isAuthenticated = true
						completion(true)
					}
				}
		}
	}

	func signIn(
		email: String, password: String, completion: @escaping (Bool) -> Void
	) {
		Auth.auth().signIn(withEmail: email, password: password) {
			[weak self] authResult, error in
			if let error = error {
				self?.errorMessage = error.localizedDescription
				completion(false)
			} else {
				self?.isAuthenticated = true
				completion(true)
			}
		}
	}

	func signInWithGoogle(callback: @escaping (Bool) -> Void) async -> Bool {
		guard let clientId = FirebaseApp.app()?.options.clientID else {
			return false
		}

		let config = GIDConfiguration(clientID: clientId)
		GIDSignIn.sharedInstance.configuration = config

		// Start the sign in flow
		guard
			let windowScene = await UIApplication.shared.connectedScenes.first
				as? UIWindowScene,
			let window = await windowScene.windows.first,
			let rootViewController = await window.rootViewController
		else {
			print("There is no root view controller")
			return false
		}

		do {
			let googleSignInResult: GIDSignInResult =
				try await GIDSignIn.sharedInstance.signIn(
					withPresenting: rootViewController)
			Message.buildLogInfo("Information of gg sign in result")
			print(googleSignInResult)

			let ggResponse = googleSignInResult.user

			guard let idToken = ggResponse.idToken else {
				Message.buildLogError("ID Token not found")
				return false
			}

			let accessToken = ggResponse.accessToken
			let credentialConfig = GoogleAuthProvider.credential(
				withIDToken: idToken.tokenString,
				accessToken: accessToken.tokenString)

			let authComplete = try await Auth.auth().signIn(
				with: credentialConfig)
			Message.buildLogInfo("\nAuth complete data")
			print(authComplete)

			let userInfoDetails = authComplete.user
			print(userInfoDetails)

			Message.buildLogInfo(
				"\n\nUser \(userInfoDetails.uid) signed in with \(userInfoDetails.email ?? "Unknown")"
			)

			// Check exist of account
			let poolDataTransfer = UserProfile(
				id: userInfoDetails.uid,
				name: userInfoDetails.displayName!,
				email: userInfoDetails.email!)

			let isUserExist = try await isUserExistInServer(
				id: userInfoDetails.uid)

			if !isUserExist {
				insertUserToServer(profileData: poolDataTransfer)
				try await loadCurrentUserProfile()
			}

			callback(true)
		} catch {
			callback(false)
		}
		return false

	}

	// Sign in with google

	func insertUserToServer(profileData: UserProfile) {
		do {
			try db.collection("user_profiles")
				.document(profileData.id)
				.setData(from: profileData)
		} catch let error {
			Message.buildLogError(error.localizedDescription)
		}
	}

	func signOut() {
		do {
			try Auth.auth().signOut()
			self.isAuthenticated = false
			self.signInEnable = true
		} catch let error {
			self.errorMessage =
				"Failed to sign out: \(error.localizedDescription)"
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

	func isUserExistInServer(id: String) async throws -> Bool {
		let docRef = db.collection("user_profiles").document(id)

		do {
			let document = try await docRef.getDocument()
			Message.buildLogInfo("[FOUNDED]: User was founded in server")

			return document.exists
		} catch {
			Message.buildLogError("[NOT FOUND]: User was founded in server")
		}

		return false
	}

	func loadCurrentUserProfile() async throws {
		guard let uId = Auth.auth().currentUser?.uid else {
			return
		}

		do {
			let snapshot = try await db.collection("user_profiles").document(
				uId
			).getDocument()
			guard let data = snapshot.data() else { return }

			DispatchQueue.main.async {
				self.userProfile = UserProfile(
					id: data["id"] as! String,
					name: data["name"] as! String,
					email: data["email"] as! String)
			}
		} catch {
			print("Error loading user profile: \(error.localizedDescription)")
		}

	}
}

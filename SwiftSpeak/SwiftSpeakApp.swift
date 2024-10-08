//
//  SwiftSpeakApp.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import Firebase

@main
struct SwiftSpeakApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager()
    @State private var isSplashActive = false
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } 
//            else if !authManager.isAuthenticated {
//                SplashScreen(isActive: $isSplashActive)
//            }
            else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
    }
}

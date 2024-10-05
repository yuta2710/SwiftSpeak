//
//  SwiftSpeakApp.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct SwiftSpeakApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            //                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            //            MeetingView()
        }
    }
}

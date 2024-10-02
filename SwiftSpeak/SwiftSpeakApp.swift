//
//  SwiftSpeakApp.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI

@main
struct SwiftSpeakApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//            MeetingView()
        }
    }
}

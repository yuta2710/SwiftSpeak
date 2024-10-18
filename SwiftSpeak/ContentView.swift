//
//  ContentView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
	@State private var currentTab: Tab = .profile
	@StateObject private var speechRecognizer = SpeechRecognizer()

	init() {
		UITabBar.appearance().backgroundColor = .white
	}
	
	var body: some View {
		TabView(selection: $currentTab) {
			MeetingView(speechRecognizer: speechRecognizer)
				.tabItem {
					Image(systemName: Tab.home.rawValue)
					Text("Home")
				}
				.tag(Tab.home)
			
			UserSelectSpeedTypeView()
				.tabItem {
					Image(systemName: Tab.search.rawValue)
					Text("Search")
				}
				.tag(Tab.search)

			RecordingsListView(speechRecognizer: speechRecognizer)
				.tabItem {
					Image(systemName: "microphone.fill")
					Text("Recordings")
				}
				.tag(2)
			
			UserProfileView()
				.tabItem {
					Image(systemName: "person.crop.circle")
					Text("Profile")
				}
				.tag(Tab.profile)
		}
		.ignoresSafeArea(.keyboard)
	}
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

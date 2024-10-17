//
//  ContentView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var currentTab: Tab = Tab.profile
	@StateObject var speechRecognizer = SpeechRecognizer()
	
    init() {
        UITabBar.appearance().backgroundColor = .white
    }
    
    var body: some View {
        NavigationView {
            VStack (spacing: 0.0) {
                TabView(selection: $currentTab) {
					MeetingView(speechRecognizer: SpeechRecognizer())
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
							Image(systemName: "list.bullet")
							Text("Recordings")
						}
					
                    UserProfileView()
                        .tabItem {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                        }
                        .tag(Tab.profile)
                }
            }
            .ignoresSafeArea(.keyboard)
			.onAppear{
				speechRecognizer.loadRecordings()
			}
        }
    }
}
#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

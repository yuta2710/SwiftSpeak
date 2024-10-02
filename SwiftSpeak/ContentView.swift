//
//  ContentView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var currentTab: Tab = Tab.home
    
    init() {
        UITabBar.appearance().backgroundColor = .white
    }
    
    var body: some View {
        NavigationView {
            VStack (spacing: 0.0) {
                TabView(selection: $currentTab) {
                    MeetingView()
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
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
#Preview {
    ContentView()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

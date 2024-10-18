//
//  ContentView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
  @AppStorage("selectedTab") var selectedTab: Tab2 = .search
  
  @State private var currentTab: Tab = Tab.profile
  @StateObject var speechRecognizer = SpeechRecognizer()
  
  init() {
    UITabBar.appearance().backgroundColor = .white
  }
  
  var body: some View {
    ZStack {
      Color(hex: "C4E1F6")
        .ignoresSafeArea()
      Group {
        switch selectedTab {
          case .search:
            MeetingView(speechRecognizer: SpeechRecognizer())
          case .timer:
            UserSelectSpeedTypeView()
          case .bell:
            RecordingsListView()
              .environmentObject(speechRecognizer)
          case .user:
            UserProfileView()
        }
      }
      
      TabBar()
        .background(
          LinearGradient(colors: [Color("Background").opacity(0), Color("Background")], startPoint: .top, endPoint: .bottom)
            .frame(height: 150)
            .offset(y: 36)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        )
//        .ignoresSafeArea()
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AuthenticationManager())
  //        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}






//    NavigationView {
//      VStack (spacing: 0.0) {
//        TabView(selection: $currentTab) {
//          MeetingView(speechRecognizer: SpeechRecognizer())
//            .tabItem {
//              Image(systemName: Tab.home.rawValue)
//              Text("Home")
//            }
//            .tag(Tab.home)
//
//          UserSelectSpeedTypeView()
//            .tabItem {
//              Image(systemName: Tab.search.rawValue)
//              Text("Search")
//            }
//            .tag(Tab.search)
//
//          RecordingsListView(speechRecognizer: speechRecognizer)
//            .tabItem {
//              Image(systemName: "list.bullet")
//              Text("Recordings")
//            }
//
//          UserProfileView()
//            .tabItem {
//              Image(systemName: "person.crop.circle")
//              Text("Profile")
//            }
//            .tag(Tab.profile)
//        }
//      }
//      .ignoresSafeArea(.keyboard)
//      .onAppear{
//        speechRecognizer.loadRecordings()
//      }
//    }
//  }

//
//  TabBar.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 18/10/24.
//

import SwiftUI
import RiveRuntime

enum Tab2: String {
  case search
  case timer
  case bell
  case user
}

struct TabBarItem: Identifiable {
  var id = UUID()
  var icon: RiveViewModel
  var tab: Tab2
}

var tabItems = [
  TabBarItem(icon: RiveViewModel(fileName: "icons", stateMachineName: "SEARCH_Interactivity", artboardName: "SEARCH"), tab: Tab2.search),
  TabBarItem(icon: RiveViewModel(fileName: "icons", stateMachineName: "TIMER_Interactivity", artboardName: "TIMER"), tab: Tab2.timer),
  TabBarItem(icon: RiveViewModel(fileName: "icons", stateMachineName: "BELL_Interactivity", artboardName: "BELL"), tab: Tab2.bell),
  TabBarItem(icon: RiveViewModel(fileName: "icons", stateMachineName: "USER_Interactivity", artboardName: "USER"), tab: Tab2.user),
]

struct TabBar: View {
  @AppStorage("selectedTab") var selectedTab: Tab2 = .search
  let icon = RiveViewModel(fileName: "icons", stateMachineName: "SEARCH_Interactivity", artboardName: "SEARCH")
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        ForEach(tabItems) { item in
          Button(action: {
            try? item.icon.setInput("active", value: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              try? item.icon.setInput("active", value: false)
            }
            withAnimation {
              selectedTab = item.tab
            }
          }, label: {
            item.icon.view()
              .frame(width: 36, height: 36)
              .opacity(item.tab == selectedTab ? 1 : 0.5)
              .shadow(color: selectedTab == item.tab ? Color(hex: "ff2d55") : Color.clear, radius: 8, x: 0, y: 2)
              .shadow(color: selectedTab == item.tab ? Color(hex: "ff2d55").opacity(0.5) : Color.clear, radius: 10, x: 0, y: 2)
              .shadow(color: selectedTab == item.tab ? Color(hex: "FA57C1").opacity(0.5) : Color.clear, radius: 10, x: 0, y: 2)
              .background(
                VStack {
                  RoundedRectangle(cornerRadius: 2)
                    .frame(width: selectedTab == item.tab ? 20 : 0, height: 4)
                    .offset(y: -4)
                    .opacity(selectedTab == item.tab ? 1 : 0)
                  
                  Spacer()
                }
              )
             
          })
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
        }
      }
      .background(Color("Background 2").opacity(0.8))
      .background(.ultraThinMaterial)
      .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .shadow(color: Color("Background 2").opacity(0.3), radius: 20, x: 0, y: 20)
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(.linearGradient(colors: [.white.opacity(0.5), .white.opacity(0)], startPoint: .topLeading, endPoint: .bottomTrailing))
      )
      .padding(.horizontal, 24)
    }
  }
}

#Preview {
  TabBar()
}

//
//  RadialButton.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 19/10/24.
//

import SwiftUI

struct RadialButton: View {
  @State private var trigger = false
  
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 30)
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .foregroundStyle(
          //          .linearGradient(colors: [Color.init(hex: "EEF7FF"), Color.init(hex: "5755FE").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
          .black
            .shadow(.inner(color: .white.opacity(0.2), radius: 0, x: 1, y: 1))
            .shadow(.inner(color: .white.opacity(0.05), radius: 4, x: 0, y: -4))
          //          .shadow(.inner(color: .black.opacity(0.5), radius: 30, y: 30))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 30)
            .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .background( // important part
          ZStack {
            AngularGradient(colors: [.red, .blue, .teal, .red], center: .center, angle: .degrees(trigger ? 360 : 0))
              .cornerRadius(30)
              .blur(radius: 15)
            AngularGradient(colors: [.white, .blue, .teal, .white], center: .center, angle: .degrees(trigger ? 360 : 0))
              .cornerRadius(30)
              .blur(radius: 15)
          }
        )
        .onAppear(){ // important part
          withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
              trigger = true
          }
        }
        .padding([.vertical, .horizontal], 16)
      
      HStack(spacing: 8.0) {
        Image(systemName: "applelogo")
          .resizable()
          .frame(width: 25, height: 30)
          .foregroundStyle(LinearGradient(colors: [Color("Pink Gradient 1"), Color("Pink Gradient 2")], startPoint: .topLeading, endPoint: .topTrailing))
        
        Text("Sign In with Google")
          .foregroundColor(.white)
          .font(.custom("Poppins-Medium", size: 18))
      }
    }
  }
}

#Preview {
  RadialButton()
}

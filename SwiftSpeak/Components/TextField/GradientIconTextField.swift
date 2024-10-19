//
//  GradientIconTextField.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 19/10/24.
//

import SwiftUI

struct GradientIconTextField: View {
  @Environment(\.colorScheme) var systemScheme
  var gradient1: [Color] = [
    Color.init(red: 101/255, green: 134/255, blue: 1),
    Color.init(red: 1, green: 64/255, blue: 80/255),
    Color.init(red: 109/255, green: 1, blue: 185),
    Color.init(red: 39/255, green: 232/255, blue: 1),
  ]
  var iconName: String
  
  @Binding var currentlyEditing: Bool
  @Binding var textFieldInputString: String
//  @Binding var iconBounce: Bool
  
  @State private var colorAngle: Double = 0.0
  
  var body: some View {
    ZStack {
      if systemScheme == .dark {
        VisualEffectBlur(blurStyle: .dark) {
          ZStack {
            if currentlyEditing || !textFieldInputString.isEmpty {
              AngularGradient(gradient: Gradient(colors: gradient1), center: .center, angle: .degrees(colorAngle))
                .blur(radius: 10)
                .onAppear(){
                  withAnimation(.linear(duration: 7)) {
                    self.colorAngle += 350
                  }
                }
            }
            Color("TertiaryBackground")
              .cornerRadius(12.0)
              .opacity(0.5)
              .blur(radius: 3.0)
          }
        }
        .cornerRadius(12.0)
        .overlay(
          ZStack {
            RoundedRectangle(cornerRadius: 12.0, style: .continuous)
              .stroke(Color.white, lineWidth: 1.0)
              .blendMode(.overlay)
            
            Image(systemName: iconName)
              .gradientForegroundIntoView(group: [Color("Pink Gradient 1"), Color("Pink Gradient 2")])
              .font(.system(size: 17, weight: .medium))
          }
        )
      }
      
    }
    .frame(width: 36, height: 36, alignment: .center)
    .padding([.vertical, .leading], 8)
//    .onTapGesture {
//        // Animate the bounce when tapped
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.3)) {
//            iconBounce = true
//        }
//    }
      }
}

#Preview {
//  GradientIconTextField(iconName: "key.fill", currentlyEditing: .constant(true), textFieldInputString: .constant("loi"), iconBounce: .constant(true))
  AuthenticationView()
    .environmentObject(AuthenticationManager())
}

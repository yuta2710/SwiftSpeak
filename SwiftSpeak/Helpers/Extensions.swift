//
//  StyleHelpers.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 05/10/2024.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
  public func gradientForegroundIntoView(group: [Color]) -> some View {
    self
      .overlay(
        LinearGradient(colors: group, startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .mask(self)
  }
  
  public func gradientTextFieldBackgroundModifier(basedOn mode: ColorScheme) -> some View {
      if mode == .dark {
          return self
          .background(.black.opacity(0.6))
          .cornerRadius(12)
          
      } else {
          return self
          .background(.black.opacity(0.6))
          .cornerRadius(12)
//          .overlay(
//            RoundedRectangle(cornerRadius: 24, style: .continuous)
//              .stroke(Color.black, lineWidth: 1)
////              .mask(self)
//          )
//          .mask(self)
      }
  }
 }

extension View {
    func multicolorGlow() -> some View {
        ZStack {
            ForEach(0..<2) { i in
                Rectangle()
                    .fill(AngularGradient(gradient: Gradient(colors:
[Color.blue, Color.purple, Color.orange, Color.red]), center: .center))
                    .frame(maxHeight: .infinity, alignment: .center)
                    .mask(self.blur(radius: 20))
                    .overlay(self.blur(radius: 5 - CGFloat(i * 5)))
                    .ignoresSafeArea()
                    
            }
        }
    }
}

extension View {
  func setMulticolorGlow(basedOn mode: ColorScheme) -> some View {
    self
      .modifierIf(condition: mode == .dark) { view in
        view.multicolorGlow()
      }
  }
}

//extension View {
//  public func gradientTextFieldBackgroundModifier(basedOn mode: ColorScheme) {
//    if mode == .dark {
//      self.background(Color(red: 26/255, green: 20/255, blue: 51/255).cornerRadius(16).opacity(0.8))
//    }else{
//      self.background(.ultraThinMaterial)
//    }
//  }
//}

extension View {
  @ViewBuilder
  func modifierIf<Content: View>(condition: Bool, modifier: (Self) -> Content) -> some View {
    if condition {
      modifier(self)
    }
  }
}

#Preview {
  AuthenticationView()
    .environmentObject(AuthenticationManager())
}

//
//  SplashScreen.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 05/10/2024.
//

import SwiftUI

struct SplashScreen: View {
    @State private var scale = 0.7
    @Binding var isActive: Bool
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 100))
                    .foregroundStyle(LinearGradient(gradient: /*@START_MENU_TOKEN@*/Gradient(colors: [Color.red, Color.blue])/*@END_MENU_TOKEN@*/, startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/))
                Text("Authenticating")
                    .font(.system(size: 20))
            }.scaleEffect(scale)
            .onAppear{
                withAnimation(.easeIn(duration: 0.7)) {
                    self.scale = 0.9
                }
            }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashScreen(isActive: .constant(true))
}

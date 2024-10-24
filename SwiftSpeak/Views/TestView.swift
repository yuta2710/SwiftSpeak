//
//  TestView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 22/10/24.
//

import SwiftUI
import Translation

struct TestView: View {
    @State var text = "We can’t wait to see what you will Create with Swift."
    @State var showTranslation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }
            
            .translationPresentation(isPresented: $showTranslation, text: text)
            
            .toolbar {
                Button {
                    showTranslation.toggle()
                } label: {
                    Image(systemName: "translate")
                }
            }
        }
    }
}

#Preview {
    TestView()
}

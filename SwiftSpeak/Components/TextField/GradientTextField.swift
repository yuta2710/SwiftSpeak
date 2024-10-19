//
//  GradientTextField.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 19/10/24.
//

import SwiftUI

struct GradientTextField: View {
  var textFieldPlaceholder: String
  var textFieldIconString: String
  var isPassword: Bool
  
  @Environment(\.colorScheme) var mode
  
  @Binding var isCurrentlyEditingTextField: Bool
  @Binding var textFieldInputString: String
  @Binding var iconBounce: Bool
  
  @FocusState private var didSecureFieldBeingFocused: Bool
  
  private let generator = UISelectionFeedbackGenerator()
  
  
  var body: some View {
    HStack {
      GradientIconTextField(iconName: textFieldIconString, currentlyEditing: $isCurrentlyEditingTextField, textFieldInputString: $textFieldInputString)
        .scaleEffect(iconBounce ? 1.5 : 1.0)
      
      if isPassword {
        SecureField("Password", text: $textFieldInputString)
          .colorScheme(.dark)
          .foregroundColor(Color.white.opacity(0.7))
          .font(.custom("Poppins-Bold", size: 20))
          .focused($didSecureFieldBeingFocused)
          .onChange(of: didSecureFieldBeingFocused){ isFocused in
            isCurrentlyEditingTextField = isFocused
            print("Field is currently focused: \(isFocused)")
          }
          .onChange(of: textFieldInputString){ newValue in
            print("Editing status: \(isCurrentlyEditingTextField)")
            if newValue.isEmpty {
              isCurrentlyEditingTextField = false
            }
            else {
              if isCurrentlyEditingTextField {
                generator.selectionChanged()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0.5)) {
                  iconBounce.toggle()
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0.5).delay(0.15)){
                  iconBounce.toggle()
                }
              }
            }
          }
      }else {
        TextField(textFieldPlaceholder, text: $textFieldInputString) { isEditing in
          print("Concac ", isEditing)
          isCurrentlyEditingTextField = isEditing
          
          if isEditing {
            generator.selectionChanged()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0.5)) {
              iconBounce.toggle()
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0.5).delay(0.15)){
              iconBounce.toggle()
            }
          }
        }
        .colorScheme(.dark)
        .foregroundColor(Color.white.opacity(0.7))
        .font(.custom("Poppins-Medium", size: 20))
        .focused($didSecureFieldBeingFocused)
        .onChange(of: didSecureFieldBeingFocused) { isFocused in
          isCurrentlyEditingTextField = isFocused
          print("Field is currently focused: \(isFocused)")
        }
        .onChange(of: textFieldInputString) { newValue in
          if newValue.isEmpty {
            isCurrentlyEditingTextField = false
          }
          
        }
      }
      
    }
    .padding([.vertical, .horizontal], 8)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.white, lineWidth: 1.0)
        .opacity(0.4)
        .blendMode(.overlay)
    )
//    .background(Color(red: 26/255, green: 20/255, blue: 51/255).cornerRadius(16).opacity(0.8))
    .gradientTextFieldBackgroundModifier(basedOn: mode)
  }
}



#Preview {
//  GradientTextField(textFieldPlaceholder: "Email", textFieldIconString: "textformat.alt", isPassword: true, isCurrentlyEditingTextField: .constant(true), textFieldInputString: .constant(""), iconBounce: .constant(true))
  AuthenticationView()
    .environmentObject(AuthenticationManager())
}

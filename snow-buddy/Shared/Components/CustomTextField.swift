//
//  CustomTextField.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 3/10/2025.
//

import SwiftUI

struct CustomTextField: View {
    var placeholder: String
        @Binding var text: String
        var borderColor: Color = .purple
        var cornerRadius: CGFloat = 20
        
        @FocusState private var isFocused: Bool
        
        var body: some View {
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .padding()
                .background(isFocused ? Color("TextFieldBackground") : Color.gray.opacity(0.2))
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1.5)
                )
                .focused($isFocused)
                .animation(.easeIn(duration: 0.1), value: isFocused)
        }}

#Preview {
    CustomTextField(placeholder: "email", text: .constant(""))
}

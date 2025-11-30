//
//  CustomButton.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 3/10/2025.
//

import SwiftUI

struct CustomButton: View {
    var title: String
    var style: CustomButtonStyle = .primary
    var activeBackgroundColor: Color = Color("TertiaryColor")
    var cornerRadius: CGFloat = 20
    var isDisabled: Bool = false
    var action: () -> Void
    var isActive: Bool = false
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color("PrimaryColor")
        case .secondary:
            return Color("SecondaryColor")
        case .tertiary:
            return Color("TertiaryColor")
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .black
        case .secondary:
            return .white
        case .tertiary:
            return .black
        }
    }
        
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(textColor)
                .lexendFont(.bold, size: 18)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .padding(.horizontal)
        .background(isDisabled
                    ? backgroundColor.opacity(0.5)
                    : (isActive ? activeBackgroundColor : backgroundColor)
        )
        .cornerRadius(cornerRadius)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct DangerButton: View {
    var title: String
    var backgroundColor: Color = .red
    var activeBackgroundColor: Color = .red
    var textColor: Color = .white
    var cornerRadius: CGFloat = 20
    var isDisabled: Bool = false
    var action: () -> Void
    var isActive: Bool = false
    
    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .foregroundColor(textColor)
                .lexendFont(.bold, size: 18)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .padding(.horizontal)
        .background(isDisabled
                    ? backgroundColor.opacity(0.5)
                    : (isActive ? activeBackgroundColor : backgroundColor)
        )
        .cornerRadius(cornerRadius)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        
    }
}

enum CustomButtonStyle {
    case primary
    case secondary
    case tertiary
}



#Preview {
    CustomButton(title: "Login Now", action: {print("Preview Button Pressed")})
    
    CustomButton(title: "Login Now", style: .secondary, action: {print("Preview Button Pressed")})
    
    CustomButton(title: "Login Now", style: .tertiary, action: {print("Preview Button Pressed")})
    
    DangerButton(title: "Delete Data", action: {print("Delete Button Pressed")})
}

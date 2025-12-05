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

struct AddFriendButton: View {
    var state: FriendRequestButtonState = .idle
    var action: () -> Void

    private var iconName: String {
        switch state {
        case .idle:
            return "person.badge.plus.fill"
        case .sending:
            return "person.badge.plus.fill"
        case .sent:
            return "checkmark"
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:
            return Color("PrimaryColor")
        case .sending:
            return Color.gray
        case .sent:
            return Color.green
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if state == .sending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: state == .sent ? .bold : .regular))
                        .foregroundColor(.black)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(state != .idle)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

enum FriendRequestButtonState {
    case idle       // Ready to send request
    case sending    // Currently sending
    case sent       // Request sent successfully
}

struct CancelRequestButton: View {
    var action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isDisabled ? Color.gray : Color.red)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(isDisabled)
    }
}

struct AcceptRequestButton: View {
    var action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isDisabled ? Color.gray : Color.green)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(isDisabled)
    }
}

struct RejectRequestButton: View {
    var action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isDisabled ? Color.gray : Color.red)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "Login Now", action: {print("Preview Button Pressed")})

        CustomButton(title: "Login Now", style: .secondary, action: {print("Preview Button Pressed")})

        CustomButton(title: "Login Now", style: .tertiary, action: {print("Preview Button Pressed")})

        DangerButton(title: "Delete Data", action: {print("Delete Button Pressed")})

        HStack(spacing: 20) {
            AddFriendButton(state: .idle, action: {print("Add Friend Pressed")})
            AddFriendButton(state: .sending, action: {})
            AddFriendButton(state: .sent, action: {})
        }

        HStack(spacing: 20) {
            AcceptRequestButton(action: {print("Accept Pressed")})
            RejectRequestButton(action: {print("Reject Pressed")})
            CancelRequestButton(action: {print("Cancel Pressed")})
        }
    }
    .padding()
}

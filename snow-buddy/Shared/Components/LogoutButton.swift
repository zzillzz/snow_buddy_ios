//
//  LogoutButton.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/11/2025.
//

import SwiftUI

struct LogoutButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))

                Text("Logout")
                    .lexendFont(.semiBold, size: 16)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack {
        LogoutButton {
            print("Logout tapped")
        }
        .padding()
    }
    .appBackground()
}

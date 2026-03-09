//
//  PrimaryActionButton.swift
//  snow-buddy
//
//  Created by Claude on 12/12/2025.
//

import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }

                Text(title)
                    .lexendFont(.semiBold, size: 17)
            }
            .foregroundColor(isEnabled ? .black : .gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color("PrimaryColor") : Color("PrimaryColor").opacity(0.5))
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Enabled Buttons")
            .lexendFont(.bold, size: 20)

        PrimaryActionButton(
            title: "Start Session",
            icon: "play.circle.fill",
            action: {}
        )

        PrimaryActionButton(
            title: "Create Group",
            icon: "plus.circle.fill",
            action: {}
        )

        PrimaryActionButton(
            title: "Continue",
            action: {}
        )

        Divider()
            .padding(.vertical)

        Text("Disabled Buttons")
            .lexendFont(.bold, size: 20)

        PrimaryActionButton(
            title: "Start Session",
            icon: "play.circle.fill",
            action: {}
        )
        .disabled(true)

        PrimaryActionButton(
            title: "Create Group",
            icon: "plus.circle.fill",
            action: {}
        )
        .disabled(true)

        PrimaryActionButton(
            title: "Continue",
            action: {}
        )
        .disabled(true)
    }
    .padding()
    .appBackground()
}

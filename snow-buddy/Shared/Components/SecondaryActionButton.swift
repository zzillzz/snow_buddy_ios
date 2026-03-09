//
//  SecondaryActionButton.swift
//  snow-buddy
//
//  Created by Claude on 12/12/2025.
//

import SwiftUI

struct SecondaryActionButton: View {
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
            .background(isEnabled ? Color("SecondaryColor") : Color("SecondaryColor").opacity(0.5))
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Enabled Buttons")
            .lexendFont(.bold, size: 20)

        SecondaryActionButton(
            title: "Cancel",
            icon: "xmark.circle.fill",
            action: {}
        )

        SecondaryActionButton(
            title: "View Details",
            icon: "info.circle.fill",
            action: {}
        )

        SecondaryActionButton(
            title: "Dismiss",
            action: {}
        )

        Divider()
            .padding(.vertical)

        Text("Disabled Buttons")
            .lexendFont(.bold, size: 20)

        SecondaryActionButton(
            title: "Cancel",
            icon: "xmark.circle.fill",
            action: {}
        )
        .disabled(true)

        SecondaryActionButton(
            title: "View Details",
            icon: "info.circle.fill",
            action: {}
        )
        .disabled(true)

        SecondaryActionButton(
            title: "Dismiss",
            action: {}
        )
        .disabled(true)
    }
    .padding()
    .appBackground()
}

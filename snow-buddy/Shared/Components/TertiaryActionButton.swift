//
//  TertiaryActionButton.swift
//  snow-buddy
//
//  Created by Claude on 12/12/2025.
//

import SwiftUI

struct TertiaryActionButton: View {
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
            .foregroundColor(isEnabled ? Color.adaptiveInverse : .gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.adaptive : Color.adaptive.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Enabled Buttons")
            .lexendFont(.bold, size: 20)

        TertiaryActionButton(
            title: "Archive",
            icon: "archivebox.fill",
            action: {}
        )

        TertiaryActionButton(
            title: "Share",
            icon: "square.and.arrow.up",
            action: {}
        )

        TertiaryActionButton(
            title: "More Options",
            action: {}
        )

        Divider()
            .padding(.vertical)

        Text("Disabled Buttons")
            .lexendFont(.bold, size: 20)

        TertiaryActionButton(
            title: "Archive",
            icon: "archivebox.fill",
            action: {}
        )
        .disabled(true)

        TertiaryActionButton(
            title: "Share",
            icon: "square.and.arrow.up",
            action: {}
        )
        .disabled(true)

        TertiaryActionButton(
            title: "More Options",
            action: {}
        )
        .disabled(true)
    }
    .padding()
    .appBackground()
}

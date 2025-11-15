//
//  ListRow.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/11/2025.
//

import SwiftUI

// MARK: - NavigationLink List Row
struct ListRow<Destination: View>: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let destination: Destination

    init(
        icon: String? = nil,
        iconColor: Color = Color("PrimaryColor"),
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            ListRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
                showChevron: showChevron
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button List Row (for actions without navigation)
struct ListRowButton: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let action: () -> Void

    init(
        icon: String? = nil,
        iconColor: Color = Color("PrimaryColor"),
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ListRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
                showChevron: showChevron
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shared Content View
private struct ListRowContent: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon (optional)
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lexendFont(.medium, size: 16)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .lexendFont(.regular, size: 13)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Chevron (optional)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryColor").opacity(0.2))
        )
    }
}

struct ListRowWithToggle: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(
        icon: String? = nil,
        iconColor: Color = Color("PrimaryColor"),
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon (optional)
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lexendFont(.medium, size: 16)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .lexendFont(.regular, size: 13)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryColor").opacity(0.2))
        )
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 12) {
            // Navigation rows (with NavigationLink)
            ListRow(
                icon: "person.fill",
                iconColor: Color("PrimaryColor"),
                title: "Profile"
            ) {
                Text("Profile Settings")
            }

            ListRow(
                icon: "bell.fill",
                iconColor: Color("SecondaryColor"),
                title: "Notifications",
                subtitle: "Manage your alerts"
            ) {
                Text("Notifications Settings")
            }

            ListRow(
                icon: "lock.fill",
                iconColor: Color("TertiaryColor"),
                title: "Privacy"
            ) {
                Text("Privacy Settings")
            }

            // Button rows (for actions without navigation)
            ListRowButton(
                icon: "arrow.right.square.fill",
                iconColor: Color("PrimaryColor"),
                title: "Logout",
                action: { print("Logout tapped") }
            )

            ListRowButton(
                title: "Delete Account",
                action: { print("Delete tapped") }
            )

            // List row with toggle
            ListRowWithToggle(
                icon: "location.fill",
                iconColor: .blue,
                title: "Location Services",
                subtitle: "Allow location tracking",
                isOn: .constant(true)
            )
        }
        .padding()
        .appBackground()
    }
}

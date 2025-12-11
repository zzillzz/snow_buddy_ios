//
//  LocationSharingToggle.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct LocationSharingToggle: View {
    @Binding var isSharing: Bool
    let batteryLevel: Int
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Toggle row
            Toggle(isOn: Binding(
                get: { isSharing },
                set: { _ in onToggle() }
            )) {
                HStack(spacing: 8) {
                    Image(systemName: isSharing ? "location.fill" : "location.slash")
                        .foregroundColor(isSharing ? .green : .gray)
                        .font(.body)

                    Text(isSharing ? "Sharing Location" : "Share Location")
                        .lexendFont(.semiBold, size: 15)
                }
            }
            .toggleStyle(SwitchToggleStyle())

            // Battery info (shown when sharing)
            if isSharing {
                HStack(spacing: 6) {
                    Image(systemName: batteryIcon)
                        .font(.caption)
                        .foregroundColor(batteryColor)

                    Text("Battery: \(batteryLevel)%")
                        .lexendFont(.regular, size: 12)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Battery warning
                    if batteryLevel < 20 {
                        Text("Low Battery")
                            .lexendFont(.medium, size: 11)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryContainerColor"))
        )
    }

    private var batteryIcon: String {
        if batteryLevel >= 75 { return "battery.100" }
        if batteryLevel >= 50 { return "battery.75" }
        if batteryLevel >= 25 { return "battery.25" }
        return "battery.0"
    }

    private var batteryColor: Color {
        if batteryLevel < 20 { return .red }
        if batteryLevel < 50 { return .orange }
        return .green
    }
}

#Preview {
    VStack(spacing: 20) {
        LocationSharingToggle(
            isSharing: .constant(true),
            batteryLevel: 85,
            onToggle: {}
        )

        LocationSharingToggle(
            isSharing: .constant(true),
            batteryLevel: 35,
            onToggle: {}
        )

        LocationSharingToggle(
            isSharing: .constant(true),
            batteryLevel: 15,
            onToggle: {}
        )

        LocationSharingToggle(
            isSharing: .constant(false),
            batteryLevel: 100,
            onToggle: {}
        )
    }
    .padding()
    .appBackground()
}

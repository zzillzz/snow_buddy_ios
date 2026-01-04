//
//  ParticipantPin.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct ParticipantPin: View {
    let participant: ParticipantLocation

    var body: some View {
        VStack(spacing: 4) {
            // Speed badge (if moving)
            if let speed = participant.speedKmh, speed > 1 {
                Text(participant.speedShort)
                    .lexendFont(.bold, size: 10)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(speedColor(speed))
                    .cornerRadius(8)
            }

            // Avatar circle with initials
            ZStack {
                Circle()
                    .fill(participant.isOnline ? Color.blue : Color.gray)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Text(participant.username.prefix(2).uppercased())
                    .lexendFont(.bold, size: 14)
                    .foregroundColor(.white)

                // Online indicator
                if participant.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 14, y: -14)
                }
            }

            // Battery indicator (if low)
            if let battery = participant.batteryLevel, battery < 50 {
                HStack(spacing: 2) {
                    Image(systemName: participant.batteryIcon)
                        .font(.system(size: 10))
                        .foregroundColor(battery < 20 ? .red : .orange)

                    Text("\(battery)%")
                        .lexendFont(.medium, size: 9)
                        .foregroundColor(battery < 20 ? .red : .orange)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
            }
        }
    }

    private func speedColor(_ speed: Double) -> Color {
        if speed > 40 { return .red }      // Fast (>40 km/h)
        if speed > 20 { return .orange }   // Medium (20-40 km/h)
        return .green                       // Slow (1-20 km/h)
    }
}

#Preview {
    VStack(spacing: 30) {
        ParticipantPin(participant: ParticipantLocation.sample)
        ParticipantPin(participant: ParticipantLocation.movingSample)
        ParticipantPin(participant: ParticipantLocation.stationarySample)
        ParticipantPin(participant: ParticipantLocation.offlineSample)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

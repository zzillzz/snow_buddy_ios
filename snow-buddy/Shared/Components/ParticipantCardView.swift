//
//  ParticipantCardView.swift
//  snow-buddy
//
//  Created by Claude on 1/4/2026.
//

import SwiftUI

struct ParticipantCardView: View {
    let participant: ParticipantLocation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(participant.isOnline ? Color.blue : Color.gray)
                        .frame(width: 50, height: 50)

                    Text(participant.username.prefix(2).uppercased())
                        .lexendFont(.bold, size: 16)
                        .foregroundColor(.white)

                    if participant.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 18, y: -18)
                    }
                }

                // Username
                Text(participant.username)
                    .lexendFont(.medium, size: 12)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                // Speed or status
                if let speed = participant.speedKmh, speed > 1 {
                    Text("\(Int(speed)) km/h")
                        .lexendFont(.semiBold, size: 11)
                        .foregroundColor(.green)
                } else {
                    Text(participant.activityStatus)
                        .lexendFont(.regular, size: 10)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .frame(width: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

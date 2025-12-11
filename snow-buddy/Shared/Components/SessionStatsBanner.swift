//
//  SessionStatsBanner.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct SessionStatsBanner: View {
    let session: GroupSession
    let participantCount: Int

    var body: some View {
        HStack(spacing: 20) {
            // Duration
            VStack(spacing: 4) {
                Text(session.durationShort)
                    .lexendFont(.bold, size: 20)
                    .foregroundColor(.primary)

                Text("Duration")
                    .lexendFont(.regular, size: 11)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Participants
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Text("\(participantCount)")
                        .lexendFont(.bold, size: 20)
                        .foregroundColor(.primary)
                }

                Text("Online")
                    .lexendFont(.regular, size: 11)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Resort
            VStack(spacing: 4) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)

                Text(session.resort?.name ?? "Resort")
                    .lexendFont(.semiBold, size: 12)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryContainerColor"))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SessionStatsBanner(
            session: GroupSession.activeSample,
            participantCount: 5
        )

        SessionStatsBanner(
            session: GroupSession.endedSample,
            participantCount: 8
        )
    }
    .padding()
    .appBackground()
}

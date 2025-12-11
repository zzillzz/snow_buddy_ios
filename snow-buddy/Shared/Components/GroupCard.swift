//
//  GroupCard.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct GroupCard: View {
    let group: GroupModel

    var body: some View {
        HStack(spacing: 16) {
            // Left: Group icon
            ZStack {
                Circle()
                    .fill(Color("PrimaryColor"))
                    .frame(width: 50, height: 50)

                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .lexendFont(.bold, size: 16)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // Member count
                    Text(group.memberCountShort)
                        .lexendFont(.regular, size: 12)
                        .foregroundColor(.secondary)

                    // Private indicator
                    if group.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Active session indicator
                    if group.hasActiveSession {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)

                            Text("Active")
                                .lexendFont(.medium, size: 11)
                                .foregroundColor(.green)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryContainerColor"))
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        GroupCard(group: GroupModel.sample)
        GroupCard(group: GroupModel.premiumSample)
        GroupCard(group: GroupModel.fullSample)
    }
    .padding()
    .appBackground()
}

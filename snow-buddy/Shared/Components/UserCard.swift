//
//  UserCard.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/11/2025.
//

import SwiftUI

struct UserCard: View {
    let user: User?

    private var displayName: String {
        user?.username ?? user?.email ?? "Guest"
    }

    private var initials: String {
        if let username = user?.username {
            let components = username.split(separator: " ")
            if components.count >= 2 {
                return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
            }
            return String(username.prefix(2)).uppercased()
        }
        if let email = user?.email {
            return String(email.prefix(2)).uppercased()
        }
        return "G"
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("PrimaryColor"))
                    .frame(width: 60, height: 60)

                Text(initials)
                    .lexendFont(.bold, size: 20)
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .lexendFont(.bold, size: 18)
                    .foregroundColor(.primary)

                if let email = user?.email, user?.username != nil {
                    Text(email)
                        .lexendFont(.regular, size: 14)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryColor").opacity(0.2))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        UserCard(user: User(id: UUID(), email: "rider@example.com", username: "Snow Rider"))
        UserCard(user: User(id: UUID(), email: "john.doe@example.com", username: nil))
        UserCard(user: nil)
    }
    .padding()
    .appBackground()
}

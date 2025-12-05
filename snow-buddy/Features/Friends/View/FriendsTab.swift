//
//  FriendsTab.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 5/12/2025.
//

import SwiftUI

struct FriendsTab: View {
    var friends: [User]
    var isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if friends.isEmpty {
                VStack {
                    Text("No friends found, send some requests!")
                        .lexendFont(size: 17)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(friends) { user in
                            UserCard(user: user)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

#Preview {
    //FriendsTab()
}

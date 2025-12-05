//
//  FriendRequestTab.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 5/12/2025.
//

import SwiftUI

struct FriendRequestTab: View {
    @State private var username: String = ""
    @ObservedObject var viewModel: FriendsViewModel
    @State var usersFound: [User] = []
    @State private var isSearching: Bool = false
    @State private var requestStates: [UUID: FriendRequestButtonState] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search for a user")
                .lexendFont(size: 17)

            CustomTextField(
                placeholder: "Search by username",
                text: $username
            )
            .padding(.leading, 1)
            .padding(.trailing, 1)

            CustomButton(
                title: isSearching ? "Searching..." : "Find User",
                isDisabled: username.isEmpty || isSearching,
                action: {
                    Task {
                        isSearching = true
                        usersFound = await viewModel.searchUser(with: username)
                        // Reset request states for new search
                        requestStates = [:]
                        isSearching = false
                    }
                }
            )

            // Loading indicator
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .padding(.top, 8)
            }

            // Search Results
            if !usersFound.isEmpty {
                Text("Search Results")
                    .lexendFont(.bold, size: 17)
                    .padding(.top, 8)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(usersFound) { user in
                            UserCard(user: user)
                                .overlay(alignment: .trailing) {
                                    AddFriendButton(
                                        state: requestStates[user.id] ?? .idle,
                                        action: {
                                            Task {
                                                await sendFriendRequest(to: user.id)
                                            }
                                        }
                                    )
                                    .padding(.trailing, 20)
                                }
                        }
                    }
                }
            } else if !username.isEmpty && !isSearching {
                Text("No users found")
                    .lexendFont(size: 15)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .alert(item: $viewModel.alertConfig) { config in
              Alert(
                  title: Text(config.title),
                  message: Text(config.message),
                  dismissButton: .default(Text("OK"))
              )
          }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.top)
    }

    private func sendFriendRequest(to userId: UUID) async {
        // Set to sending state
        requestStates[userId] = .sending

        // Send the request
        await viewModel.sendFriendRequest(to: userId)

        // Set to sent state
        requestStates[userId] = .sent
    }
}

#Preview {
    //FriendRequestTab()
}

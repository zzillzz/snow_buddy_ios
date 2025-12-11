//
//  AddMembersView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct AddMembersView: View {
    let group: GroupModel
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var friends: [User] = []
    @State private var isLoading = false
    @State private var isAdding = false
    @State private var selectedFriendId: UUID?

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if friends.isEmpty {
                    emptyState
                } else {
                    friendsList
                }
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .lexendFont(.regular, size: 16)
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .task {
                await loadFriends()
            }
            .onChange(of: searchText) { newValue in
                Task {
                    await loadFriends()
                }
            }
        }
    }

    // MARK: - Friends List
    private var friendsList: some View {
        List {
            ForEach(friends) { friend in
                Button {
                    addMember(friend)
                } label: {
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color("PrimaryColor"))
                                .frame(width: 50, height: 50)

                            Text(friend.username?.prefix(2).uppercased() ?? "??")
                                .lexendFont(.bold, size: 16)
                                .foregroundColor(.black)
                        }

                        // Name and email
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.username ?? "Unknown")
                                .lexendFont(.semiBold, size: 15)
                                .foregroundColor(.primary)

                            
                            Text(friend.email)
                                .lexendFont(.regular, size: 13)
                                .foregroundColor(.secondary)
                            
                        }

                        Spacer()

                        // Add button
                        if isAdding && selectedFriendId == friend.id {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isAdding)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "person.2.slash" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))

            Text(searchText.isEmpty ? "No Friends Available" : "No Results")
                .lexendFont(.bold, size: 18)

            Text(searchText.isEmpty
                ? "All your friends are already in this group or you haven't added any friends yet"
                : "Try a different search term")
                .lexendFont(.regular, size: 14)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions
    private func loadFriends() async {
        isLoading = true

        // Only search if there's text, otherwise show all available friends
        if searchText.isEmpty || searchText.count >= 2 {
            friends = await viewModel.searchFriendsNotInGroup(
                groupId: group.id,
                query: searchText
            )
        }

        isLoading = false
    }

    private func addMember(_ friend: User) {
        guard !isAdding else { return }

        isAdding = true
        selectedFriendId = friend.id

        Task {
            await viewModel.addMember(
                to: group.id,
                userId: friend.id,
                role: .member
            )

            await MainActor.run {
                isAdding = false
                selectedFriendId = nil

                // Remove from list after adding
                friends.removeAll { $0.id == friend.id }

                // If list is now empty, dismiss
                if friends.isEmpty {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AddMembersView(
        group: GroupModel.sample,
        viewModel: GroupsViewModel()
    )
}

//
//  GroupsViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import Supabase

@MainActor
protocol GroupsViewModelProtocol {
    var groups: [GroupModel] { get set }
    var isLoading: Bool { get set }

    func loadGroups() async
}

@MainActor
class GroupsViewModel: GroupsViewModelProtocol, ObservableObject {
    @Published var groups: [GroupModel] = []
    @Published var isLoading: Bool = false
    @Published var alertConfig: AlertConfig?

    private let groupService = GroupService.shared
    private let friendsService = FriendsService.shared

    // MARK: - Load Data

    func loadGroups() async {
        guard let userId = try? await SupabaseService.shared.getAuthenticatedUser().id else {
            isLoading = false
            return
        }

        isLoading = true

        do {
            groups = try await groupService.getUserGroups(userId: userId)
            isLoading = false
        } catch {
            print("❌ Failed to load groups: \(error)")
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to load groups. Please try again."
                )
            }
        }
    }

    // MARK: - Group Management

    /// Create a new group
    func createGroup(
        name: String,
        description: String?,
        maxMembers: Int,
        isPrivate: Bool,
        defaultResortId: UUID? = nil
    ) async throws {
        guard !name.isEmpty else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Invalid Name",
                    message: "Group name cannot be empty."
                )
            }
            return
        }

        isLoading = true

        do {
            let groupId = try await groupService.createGroup(
                name: name,
                description: description,
                maxMembers: maxMembers,
                isPrivate: isPrivate,
                defaultResortId: defaultResortId
            )

            print("✅ Group created with ID: \(groupId)")

            // Reload groups to show the new one
            await loadGroups()

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Group '\(name)' created successfully!"
                )
            }

            isLoading = false
        } catch let error as GroupError {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: error.errorDescription ?? "Failed to create group."
                )
            }
            throw error
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to create group. Please try again."
                )
            }
            throw error
        }
    }

    /// Update group details
    func updateGroup(
        id: UUID,
        name: String?,
        description: String?,
        isPrivate: Bool?
    ) async {
        isLoading = true

        do {
            try await groupService.updateGroup(
                id: id,
                name: name,
                description: description,
                isPrivate: isPrivate
            )

            await loadGroups()

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Group updated successfully!"
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to update group. Please try again."
                )
            }
        }
    }

    /// Delete a group
    func deleteGroup(_ groupId: UUID) async {
        isLoading = true

        do {
            try await groupService.deleteGroup(id: groupId)

            // Remove from local array
            await MainActor.run {
                groups.removeAll { $0.id == groupId }
            }

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Group deleted successfully."
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to delete group. Please try again."
                )
            }
        }
    }

    // MARK: - Member Management

    /// Get members for a specific group
    func getGroupMembers(groupId: UUID) async -> [GroupMember] {
        do {
            return try await groupService.getGroupMembers(groupId: groupId)
        } catch {
            print("❌ Failed to get group members: \(error)")
            return []
        }
    }

    /// Add a member to a group
    func addMember(to groupId: UUID, userId: UUID, role: MemberRole = .member) async {
        isLoading = true

        do {
            try await groupService.addMember(groupId: groupId, userId: userId, role: role)

            // Reload groups to update member counts
            await loadGroups()

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Member added successfully!"
                )
            }

            isLoading = false
        } catch let error as GroupError {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: error.errorDescription ?? "Failed to add member."
                )
            }
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to add member. Please try again."
                )
            }
        }
    }

    /// Remove a member from a group
    func removeMember(from groupId: UUID, userId: UUID) async {
        isLoading = true

        do {
            try await groupService.removeMember(groupId: groupId, userId: userId)

            // Reload groups to update member counts
            await loadGroups()

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Member removed successfully."
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to remove member. Please try again."
                )
            }
        }
    }

    /// Update member role
    func updateMemberRole(groupId: UUID, userId: UUID, newRole: MemberRole) async {
        isLoading = true

        do {
            try await groupService.updateMemberRole(
                groupId: groupId,
                userId: userId,
                newRole: newRole
            )

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Member role updated successfully!"
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to update member role. Please try again."
                )
            }
        }
    }

    // MARK: - Search & Discovery

    /// Search for friends not in a specific group
    func searchFriendsNotInGroup(groupId: UUID, query: String) async -> [User] {
        guard let userId = try? await SupabaseService.shared.getAuthenticatedUser().id else {
            return []
        }

        guard !query.isEmpty else {
            return []
        }

        do {
            return try await groupService.searchFriendsNotInGroup(
                userId: userId,
                groupId: groupId,
                query: query
            )
        } catch {
            print("❌ Failed to search friends: \(error)")
            return []
        }
    }

    /// Search all resorts
    func searchResorts(query: String) async -> [Resort] {
        guard !query.isEmpty else {
            // Return all resorts if query is empty
            do {
                return try await groupService.getAllResorts()
            } catch {
                print("❌ Failed to get all resorts: \(error)")
                return []
            }
        }

        do {
            return try await groupService.searchResorts(query: query)
        } catch {
            print("❌ Failed to search resorts: \(error)")
            return []
        }
    }

    // MARK: - Helper Methods

    /// Check if user can create more groups (tier enforcement)
    func canCreateGroup() async -> Bool {
        guard let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString) else {
            return false
        }

        do {
            let groupCount = try await groupService.getGroupCount(ownerId: userId)

            // Check subscription tier (this would come from UserModel)
            // For now, assume free tier with max 2 groups
            let maxGroups = 2 // TODO: Get from user's subscription tier

            return groupCount < maxGroups
        } catch {
            print("❌ Failed to check group count: \(error)")
            return false
        }
    }

    /// Get user's current group count
    func getCurrentGroupCount() async -> Int {
        guard let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString) else {
            return 0
        }

        do {
            return try await groupService.getGroupCount(ownerId: userId)
        } catch {
            print("❌ Failed to get group count: \(error)")
            return 0
        }
    }
}

//
//  GroupService.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import Supabase

class GroupService {
    static let shared = GroupService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Resorts

    /// Get all resorts
    func getAllResorts() async throws -> [Resort] {
        let resorts: [Resort] =
            try await client
            .from("resorts")
            .select()
            .order("name", ascending: true)
            .execute()
            .value

        return resorts
    }

    /// Search resorts by name
    func searchResorts(query: String) async throws -> [Resort] {
        let resorts: [Resort] =
            try await client
            .from("resorts")
            .select()
            .ilike("name", pattern: "%\(query)%")
            .order("name", ascending: true)
            .limit(50)
            .execute()
            .value

        return resorts
    }

    /// Get resorts by country
    func getResortsByCountry(country: String) async throws -> [Resort] {
        let resorts: [Resort] =
            try await client
            .from("resorts")
            .select()
            .eq("country", value: country)
            .order("name", ascending: true)
            .execute()
            .value

        return resorts
    }

    /// Get a specific resort by ID
    func getResort(id: UUID) async throws -> Resort {
        let resort: Resort =
            try await client
            .from("resorts")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return resort
    }

    // MARK: - Groups

    /// Create a new group using the RPC function (enforces tier limits)
    func createGroup(
        name: String,
        description: String?,
        maxMembers: Int,
        isPrivate: Bool
    ) async throws -> UUID {
        struct CreateGroupParams: Encodable {
            let p_name: String
            let p_description: String?
            let p_max_members: Int
            let p_is_private: Bool
        }

        let params = CreateGroupParams(
            p_name: name,
            p_description: description,
            p_max_members: maxMembers,
            p_is_private: isPrivate
        )

        do {
            let response: UUID =
                try await client
                .rpc("create_group", params: params)
                .single()
                .execute()
                .value

            return response
        } catch {
            throw GroupError.from(error)
        }
    }

    /// Get all groups for a user
    func getUserGroups(userId: UUID) async throws -> [GroupModel] {
        struct GroupResponse: Decodable {
            let id: UUID
            let name: String
            let description: String?
            let owner_id: UUID
            let created_at: Date
            let updated_at: Date
            let max_members: Int
            let is_private: Bool
            let member_count: [CountWrapper]
        }
        
        struct CountWrapper: Decodable {
            let count: Int
        }

        let response: [GroupResponse] =
            try await client
            .from("groups")
            .select(
                """
                *,
                member_count:group_members(count)
                """
            )
            .in(
                "id",
                values: try await getGroupIdsForUser(userId: userId)
            )
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map { r in
            GroupModel(
                id: r.id,
                name: r.name,
                description: r.description,
                ownerId: r.owner_id,
                createdAt: r.created_at,
                updatedAt: r.updated_at,
                maxMembers: r.max_members,
                isPrivate: r.is_private,
                memberCount: r.member_count.first?.count ?? 0
            )
        }
    }

    /// Get a specific group by ID with member count
    func getGroup(id: UUID) async throws -> GroupModel {
        struct GroupResponse: Decodable {
            let id: UUID
            let name: String
            let description: String?
            let owner_id: UUID
            let created_at: Date
            let updated_at: Date
            let max_members: Int
            let is_private: Bool
        }

        let groupData: GroupResponse =
            try await client
            .from("groups")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        // Get member count
        let memberCount = try await getGroupMemberCount(groupId: id)

        // Check for active session
        let activeSessionId = try? await getActiveSessionId(groupId: id)

        return GroupModel(
            id: groupData.id,
            name: groupData.name,
            description: groupData.description,
            ownerId: groupData.owner_id,
            createdAt: groupData.created_at,
            updatedAt: groupData.updated_at,
            maxMembers: groupData.max_members,
            isPrivate: groupData.is_private,
            memberCount: memberCount,
            activeSessionId: activeSessionId
        )
    }

    /// Update group details
    func updateGroup(
        id: UUID,
        name: String?,
        description: String?,
        isPrivate: Bool?
    ) async throws {
        struct GroupUpdate: Encodable {
            let name: String?
            let description: String?
            let is_private: Bool?
            let updated_at: String

            enum CodingKeys: String, CodingKey {
                case name
                case description
                case is_private
                case updated_at
            }
        }

        let update = GroupUpdate(
            name: name,
            description: description,
            is_private: isPrivate,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("groups")
            .update(update)
            .eq("id", value: id)
            .execute()
    }

    /// Delete a group (owner only)
    func deleteGroup(id: UUID) async throws {
        try await client
            .from("groups")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Get group count for a user (for tier enforcement)
    func getGroupCount(ownerId: UUID) async throws -> Int {
        let groups: [GroupModel] =
            try await client
            .from("groups")
            .select()
            .eq("owner_id", value: ownerId)
            .execute()
            .value

        return groups.count
    }

    // MARK: - Group Members

    /// Get all members of a group
    func getGroupMembers(groupId: UUID) async throws -> [GroupMember] {
        struct MemberResponse: Decodable {
            let id: UUID
            let group_id: UUID
            let user_id: UUID
            let role: String
            let joined_at: Date
            let user: User
        }

        let response: [MemberResponse] =
            try await client
            .from("group_members")
            .select("*, user:users!user_id(*)")
            .eq("group_id", value: groupId)
            .order("joined_at", ascending: true)
            .execute()
            .value

        return response.map { r in
            GroupMember(
                id: r.id,
                groupId: r.group_id,
                userId: r.user_id,
                role: MemberRole(rawValue: r.role) ?? .member,
                joinedAt: r.joined_at,
                user: r.user
            )
        }
    }

    /// Add a member to a group (must be friends first)
    func addMember(groupId: UUID, userId: UUID, role: MemberRole = .member)
        async throws
    {
        struct AddMemberParams: Encodable {
            let group_id: UUID
            let user_id: UUID
            let role: String
        }

        let params = AddMemberParams(
            group_id: groupId,
            user_id: userId,
            role: role.rawValue
        )

        do {
            try await client
                .from("group_members")
                .insert(params)
                .execute()
        } catch {
            throw GroupError.from(error)
        }
    }

    /// Remove a member from a group
    func removeMember(groupId: UUID, userId: UUID) async throws {
        try await client
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Update member role
    func updateMemberRole(
        groupId: UUID,
        userId: UUID,
        newRole: MemberRole
    ) async throws {
        struct RoleUpdate: Encodable {
            let role: String
        }

        let update = RoleUpdate(role: newRole.rawValue)

        try await client
            .from("group_members")
            .update(update)
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Get member count for a group
    func getGroupMemberCount(groupId: UUID) async throws -> Int {
        let members: [GroupMember] =
            try await client
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .execute()
            .value

        return members.count
    }

    /// Check if user is a member of a group
    func isMember(groupId: UUID, userId: UUID) async throws -> Bool {
        let members: [GroupMember] =
            try await client
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
            .value

        return !members.isEmpty
    }

    /// Get user's role in a group
    func getUserRole(groupId: UUID, userId: UUID) async throws -> MemberRole? {
        struct MemberResponse: Decodable {
            let role: String
        }

        let response: [MemberResponse] =
            try await client
            .from("group_members")
            .select("role")
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
            .value

        guard let first = response.first else { return nil }
        return MemberRole(rawValue: first.role)
    }

    // MARK: - Helper Methods

    /// Get all group IDs for a user
    private func getGroupIdsForUser(userId: UUID) async throws -> [UUID] {
        struct GroupMemberResponse: Decodable {
            let group_id: UUID
        }

        let response: [GroupMemberResponse] =
            try await client
            .from("group_members")
            .select("group_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.map { $0.group_id }
    }

    /// Get active session ID for a group
    private func getActiveSessionId(groupId: UUID) async throws -> UUID? {
        struct SessionResponse: Decodable {
            let id: UUID
        }

        let response: [SessionResponse] =
            try await client
            .from("group_sessions")
            .select("id")
            .eq("group_id", value: groupId)
            .eq("status", value: "active")
            .limit(1)
            .execute()
            .value

        return response.first?.id
    }

    // MARK: - Search & Discovery

    /// Search for friends who are not in a specific group
    func searchFriendsNotInGroup(userId: UUID, groupId: UUID, query: String)
        async throws -> [User]
    {
        // Get user's friends
        let friends = try await FriendsService.shared.getFriends(userId: userId)

        // Get current group members
        let members = try await getGroupMembers(groupId: groupId)
        let memberIds = Set(members.map { $0.userId })

        // Filter friends not in group and matching query
        return friends.filter { friend in
            !memberIds.contains(friend.id)
                && (friend.username?.lowercased().contains(query.lowercased())
                    ?? false)
        }
    }
}

// MARK: - Group Error Handling
enum GroupError: LocalizedError {
    case groupLimitReached
    case memberLimitReached
    case notAuthorized
    case groupNotFound
    case alreadyMember
    case notFriends
    case invalidGroupName
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .groupLimitReached:
            return
                "Free tier limited to 2 groups. Upgrade to Premium for unlimited groups!"
        case .memberLimitReached:
            return "Group is at maximum capacity"
        case .notAuthorized:
            return "You don't have permission to perform this action"
        case .groupNotFound:
            return "Group not found"
        case .alreadyMember:
            return "User is already a member of this group"
        case .notFriends:
            return "You can only add friends to your group"
        case .invalidGroupName:
            return "Group name must be between 2 and 50 characters"
        case .unknown(let message):
            return message
        }
    }

    static func from(_ error: Error) -> GroupError {
        let errorMessage = error.localizedDescription

        // Parse database error messages
        if errorMessage.contains("Free tier limited to 2 groups") {
            return .groupLimitReached
        } else if errorMessage.contains("limited to 8 members") {
            return .memberLimitReached
        } else if errorMessage.contains("not authorized")
            || errorMessage.contains("permission")
        {
            return .notAuthorized
        } else if errorMessage.contains("not found") {
            return .groupNotFound
        } else if errorMessage.contains("already a member") {
            return .alreadyMember
        } else if errorMessage.contains("must be friends") {
            return .notFriends
        } else if errorMessage.contains("name_length") {
            return .invalidGroupName
        } else {
            return .unknown(errorMessage)
        }
    }
}

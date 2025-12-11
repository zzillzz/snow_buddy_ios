//
//  Group.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation

// MARK: - Member Role Enum
enum MemberRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"

    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "star.fill"
        case .member: return "person.fill"
        }
    }

    var canManageMembers: Bool {
        self == .owner || self == .admin
    }

    var canStartSession: Bool {
        self == .owner || self == .admin
    }

    var canDeleteGroup: Bool {
        self == .owner
    }
}

// MARK: - Group Model
struct GroupModel: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let ownerId: UUID
    let createdAt: Date
    let updatedAt: Date
    let maxMembers: Int
    let isPrivate: Bool

    // Optional: Populated when joining with group_members table
    var memberCount: Int?
    var members: [GroupMember]?
    var activeSessionId: UUID?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case maxMembers = "max_members"
        case isPrivate = "is_private"
        case memberCount = "member_count"
        case members
        case activeSessionId = "active_session_id"
    }

    // MARK: - Computed Properties

    /// Check if group is at maximum capacity
    var isFull: Bool {
        guard let count = memberCount else { return false }
        return count >= maxMembers
    }

    /// Number of available slots
    var availableSlots: Int {
        guard let count = memberCount else { return maxMembers }
        return max(0, maxMembers - count)
    }

    /// Privacy status text
    var privacyStatus: String {
        isPrivate ? "Private" : "Public"
    }

    /// Privacy icon
    var privacyIcon: String {
        isPrivate ? "lock.fill" : "globe"
    }

    /// Has active session
    var hasActiveSession: Bool {
        activeSessionId != nil
    }

    /// Formatted member count
    var memberCountFormatted: String {
        if let count = memberCount {
            return "\(count)/\(maxMembers) members"
        }
        return "\(maxMembers) max"
    }

    /// Short member count
    var memberCountShort: String {
        if let count = memberCount {
            return "\(count)/\(maxMembers)"
        }
        return "0/\(maxMembers)"
    }

    /// Formatted creation date
    var createdAtFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Formatted last updated
    var lastUpdatedFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    // MARK: - Helper Methods

    /// Check if a user is the owner
    func isOwner(_ userId: UUID) -> Bool {
        ownerId == userId
    }

    /// Get user's role in the group
    func getUserRole(_ userId: UUID) -> MemberRole? {
        guard let members = members else { return nil }
        return members.first(where: { $0.userId == userId })?.role
    }

    /// Check if user can invite members
    func canInviteMembers(_ userId: UUID) -> Bool {
        guard let role = getUserRole(userId) else { return false }
        return role.canManageMembers
    }

    /// Check if user can start a session
    func canStartSession(_ userId: UUID) -> Bool {
        guard let role = getUserRole(userId) else { return false }
        return role.canStartSession
    }

    /// Check if user can delete the group
    func canDeleteGroup(_ userId: UUID) -> Bool {
        guard let role = getUserRole(userId) else { return false }
        return role.canDeleteGroup
    }

    /// Check if group can accept more members
    func canAddMembers() -> Bool {
        !isFull
    }
}

// MARK: - Group Member Model
struct GroupMember: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    let role: MemberRole
    let joinedAt: Date

    // Optional: Populated when joining with users table
    var user: User?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case user
    }

    // MARK: - Computed Properties

    /// How long the user has been a member
    var membershipDuration: TimeInterval {
        Date().timeIntervalSince(joinedAt)
    }

    /// Formatted membership duration
    var membershipDurationFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: joinedAt, relativeTo: Date())
    }

    /// Short membership duration
    var membershipDurationShort: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: joinedAt, relativeTo: Date())
    }

    /// Display name for the member
    var displayName: String {
        user?.username ?? "Unknown User"
    }

    // MARK: - Helper Methods

    /// Check if member has specific role
    func hasRole(_ targetRole: MemberRole) -> Bool {
        role == targetRole
    }

    /// Check if member can manage others
    func canManageMembers() -> Bool {
        role.canManageMembers
    }

    /// Check if member can start sessions
    func canStartSession() -> Bool {
        role.canStartSession
    }
}

// MARK: - Sample Data (for previews/testing)
extension GroupModel {
    static let sample = GroupModel(
        id: UUID(),
        name: "Weekend Warriors",
        description: "Hitting the slopes every weekend!",
        ownerId: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        maxMembers: 8,
        isPrivate: false,
        memberCount: 5,
    )

    static let premiumSample = GroupModel(
        id: UUID(),
        name: "Pro Riders Club",
        description: "Advanced riders only. Premium group with extended features.",
        ownerId: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        maxMembers: 20,
        isPrivate: true,
        memberCount: 12,
        activeSessionId: UUID()
    )

    static let fullSample = GroupModel(
        id: UUID(),
        name: "Full Group",
        description: "This group is at capacity",
        ownerId: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        maxMembers: 8,
        isPrivate: false,
        memberCount: 8
    )
}

extension GroupMember {
    static let ownerSample = GroupMember(
        id: UUID(),
        groupId: UUID(),
        userId: UUID(),
        role: .owner,
        joinedAt: Date().addingTimeInterval(-2592000), // 30 days ago
        user: User.sample
    )

    static let adminSample = GroupMember(
        id: UUID(),
        groupId: UUID(),
        userId: UUID(),
        role: .admin,
        joinedAt: Date().addingTimeInterval(-1296000), // 15 days ago
        user: User.premiumSample
    )

    static let memberSample = GroupMember(
        id: UUID(),
        groupId: UUID(),
        userId: UUID(),
        role: .member,
        joinedAt: Date().addingTimeInterval(-86400), // 1 day ago
        user: User.sample
    )
}

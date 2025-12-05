//
//  Friendship.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/12/2025.
//

import Foundation

// MARK: - Friendship Model
struct Friendship: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let friendId: UUID
    let createdAt: Date

    // Optional: Populated when joining with users table
    var friend: User?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case createdAt = "created_at"
        case friend
    }

    // MARK: - Computed Properties

    /// How long users have been friends
    var friendshipDuration: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Formatted friendship duration (e.g., "3 months")
    var friendshipDurationFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Short friendship duration (e.g., "3mo")
    var friendshipDurationShort: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    // MARK: - Initializers

    init(
        id: UUID,
        userId: UUID,
        friendId: UUID,
        createdAt: Date = Date(),
        friend: User? = nil
    ) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.createdAt = createdAt
        self.friend = friend
    }

    // MARK: - Helper Methods

    /// Check if this friendship belongs to a specific user
    func belongsTo(userId: UUID) -> Bool {
        self.userId == userId
    }

    /// Get the other user's ID in this friendship
    func getOtherUserId(from currentUserId: UUID) -> UUID? {
        if userId == currentUserId {
            return friendId
        } else if friendId == currentUserId {
            return userId
        }
        return nil
    }
}

// MARK: - Friendship with User Details
/// Convenience model that combines friendship with friend's full user data
struct FriendshipWithUser: Identifiable {
    let friendship: Friendship
    let friendUser: User

    var id: UUID { friendship.id }
    var createdAt: Date { friendship.createdAt }
    var friendshipDurationFormatted: String { friendship.friendshipDurationFormatted }

    init(friendship: Friendship, friendUser: User) {
        self.friendship = friendship
        self.friendUser = friendUser
    }
}

// MARK: - Sample Data (for previews/testing)
extension Friendship {
    static let sample = Friendship(
        id: UUID(),
        userId: UUID(),
        friendId: UUID(),
        createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
        friend: User.sample
    )

    static let recentSample = Friendship(
        id: UUID(),
        userId: UUID(),
        friendId: UUID(),
        createdAt: Date().addingTimeInterval(-86400), // 1 day ago
        friend: User.premiumSample
    )
}

extension FriendshipWithUser {
    static let sample = FriendshipWithUser(
        friendship: .sample,
        friendUser: User.sample
    )
}

//
//  UserModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 22/9/2025.
//

import Foundation

// MARK: - Subscription Tier Enum
enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

// MARK: - User Model
struct User: Codable, Identifiable, Hashable {
    let id: UUID
    let username: String?
    let email: String
    let createdAt: Date
    
    // Profile
    var avatarUrl: String?
    var bio: String?

    // Stats
    var totalRuns: Int
    var totalDistanceMeters: Double
    var topSpeedMs: Double
    var lastActiveAt: Date?

    // Subscription
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?
    var maxFriendsLimit: Int?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt = "created_at"
        case avatarUrl = "avatar_url"
        case bio
        case totalRuns = "total_runs"
        case totalDistanceMeters = "total_distance_meters"
        case topSpeedMs = "top_speed_ms"
        case lastActiveAt = "last_active_at"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case maxFriendsLimit = "max_friends_limit"
    }

    // MARK: - Computed Properties

    /// Total distance in kilometers
    var totalDistanceKm: Double {
        totalDistanceMeters / 1000
    }

    /// Top speed in km/h
    var topSpeedKmh: Double {
        topSpeedMs * 3.6
    }

    /// Top speed in mph
    var topSpeedMph: Double {
        topSpeedMs * 2.237
    }

    /// Formatted last active text (e.g., "2 hours ago")
    var lastActiveFormatted: String {
        guard let lastActive = lastActiveAt else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastActive, relativeTo: Date())
    }

    /// Check if user has active premium subscription
    var isPremium: Bool {
        guard subscriptionTier == .premium else { return false }
        guard let expiresAt = subscriptionExpiresAt else { return false }
        return expiresAt > Date()
    }

    /// Check if user has unlimited friends
    var hasUnlimitedFriends: Bool {
        isPremium && maxFriendsLimit == nil
    }

    /// Get effective friend limit
    var effectiveFriendLimit: Int? {
        isPremium ? nil : maxFriendsLimit
    }

    // MARK: - Initializers

    init(
        id: UUID,
        username: String? = nil,
        email: String,
        createdAt: Date = Date(),
        avatarUrl: String? = nil,
        bio: String? = nil,
        totalRuns: Int = 0,
        totalDistanceMeters: Double = 0,
        topSpeedMs: Double = 0,
        lastActiveAt: Date? = nil,
        subscriptionTier: SubscriptionTier = .free,
        subscriptionExpiresAt: Date? = nil,
        maxFriendsLimit: Int? = 20
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = createdAt
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.totalRuns = totalRuns
        self.totalDistanceMeters = totalDistanceMeters
        self.topSpeedMs = topSpeedMs
        self.lastActiveAt = lastActiveAt
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.maxFriendsLimit = maxFriendsLimit
    }

    // MARK: - Helper Methods

    /// Check if user can add more friends
    func canAddFriend(currentFriendCount: Int) -> Bool {
        guard let limit = effectiveFriendLimit else {
            return true // Unlimited
        }
        return currentFriendCount < limit
    }

    /// Get remaining friend slots
    func remainingFriendSlots(currentFriendCount: Int) -> Int? {
        guard let limit = effectiveFriendLimit else {
            return nil // Unlimited
        }
        return max(0, limit - currentFriendCount)
    }
}

// MARK: - Sample Data (for previews/testing)
extension User {
    static let sample = User(
        id: UUID(),
        username: "snow_rider_42",
        email: "rider@example.com",
        totalRuns: 15,
        totalDistanceMeters: 45000,
        topSpeedMs: 18.5,
        lastActiveAt: Date().addingTimeInterval(-3600)
    )

    static let premiumSample = User(
        id: UUID(),
        username: "pro_skier",
        email: "pro@example.com",
        totalRuns: 120,
        totalDistanceMeters: 350000,
        topSpeedMs: 25.2,
        lastActiveAt: Date().addingTimeInterval(-1800),
        subscriptionTier: .premium,
        subscriptionExpiresAt: Date().addingTimeInterval(2592000), // 30 days
        maxFriendsLimit: nil
    )
}

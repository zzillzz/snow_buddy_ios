//
//  FriendsMock.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/12/2025.
//

import Foundation

#if DEBUG
// MARK: - Preview Data for SwiftUI Previews

struct PreviewData {

    // MARK: - Mock Users

    static let currentUser = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        username: "current_user",
        email: "current@example.com",
        totalRuns: 25,
        totalDistanceMeters: 75000,
        topSpeedMs: 20.5,
        lastActiveAt: Date(),
        subscriptionTier: .free,
        maxFriendsLimit: 20
    )

    static let premiumUser = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        username: "premium_skier",
        email: "premium@example.com",
        avatarUrl: "https://i.pravatar.cc/150?img=1",
        bio: "🎿 Pro skier | Premium member",
        totalRuns: 150,
        totalDistanceMeters: 450000,
        topSpeedMs: 28.3,
        lastActiveAt: Date().addingTimeInterval(-3600),
        subscriptionTier: .premium,
        subscriptionExpiresAt: Date().addingTimeInterval(2592000),
        maxFriendsLimit: nil
    )

    static let friend1 = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        username: "snow_rider_42",
        email: "rider42@example.com",
        avatarUrl: "https://i.pravatar.cc/150?img=2",
        totalRuns: 45,
        totalDistanceMeters: 120000,
        topSpeedMs: 22.1,
        lastActiveAt: Date().addingTimeInterval(-7200)
    )

    static let friend2 = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        username: "powder_hunter",
        email: "powder@example.com",
        avatarUrl: "https://i.pravatar.cc/150?img=3",
        bio: "Always chasing powder ❄️",
        totalRuns: 89,
        totalDistanceMeters: 267000,
        topSpeedMs: 25.7,
        lastActiveAt: Date().addingTimeInterval(-86400)
    )

    static let friend3 = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        username: "alpine_ace",
        email: "alpine@example.com",
        avatarUrl: "https://i.pravatar.cc/150?img=4",
        totalRuns: 32,
        totalDistanceMeters: 96000,
        topSpeedMs: 19.8,
        lastActiveAt: Date().addingTimeInterval(-172800)
    )

    static let stranger1 = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        username: "mountain_mike",
        email: "mike@example.com",
        avatarUrl: "https://i.pravatar.cc/150?img=5",
        totalRuns: 12,
        totalDistanceMeters: 36000,
        topSpeedMs: 18.2,
        lastActiveAt: Date().addingTimeInterval(-259200)
    )

    static let stranger2 = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
        username: "carving_queen",
        email: "queen@example.com",
        avatarUrl: "https://i.pravatar.cc/150?img=6",
        bio: "Carving enthusiast 🏂",
        totalRuns: 67,
        totalDistanceMeters: 201000,
        topSpeedMs: 24.5,
        lastActiveAt: Date().addingTimeInterval(-43200)
    )

    static let allUsers: [User] = [
        currentUser, premiumUser, friend1, friend2, friend3, stranger1, stranger2
    ]

    // MARK: - Mock Friendships

    static let friendship1 = Friendship(
        id: UUID(),
        userId: currentUser.id,
        friendId: friend1.id,
        createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
        friend: friend1
    )

    static let friendship2 = Friendship(
        id: UUID(),
        userId: currentUser.id,
        friendId: friend2.id,
        createdAt: Date().addingTimeInterval(-5184000), // 60 days ago
        friend: friend2
    )

    static let friendship3 = Friendship(
        id: UUID(),
        userId: currentUser.id,
        friendId: friend3.id,
        createdAt: Date().addingTimeInterval(-604800), // 7 days ago
        friend: friend3
    )

    static let friendships: [Friendship] = [
        friendship1, friendship2, friendship3
    ]

    static let friends: [User] = [
        friend1, friend2, friend3
    ]

    // MARK: - Mock Friend Requests

    static let receivedRequest1 = FriendRequest(
        id: UUID(),
        senderId: stranger1.id,
        receiverId: currentUser.id,
        status: .pending,
        createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
        sender: stranger1
    )

    static let receivedRequest2 = FriendRequest(
        id: UUID(),
        senderId: stranger2.id,
        receiverId: currentUser.id,
        status: .pending,
        createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
        sender: stranger2
    )

    static let receivedRequest3 = FriendRequest(
        id: UUID(),
        senderId: premiumUser.id,
        receiverId: currentUser.id,
        status: .pending,
        createdAt: Date().addingTimeInterval(-86400), // 1 day ago
        sender: premiumUser
    )

    static let sentRequest1 = FriendRequest(
        id: UUID(),
        senderId: currentUser.id,
        receiverId: stranger1.id,
        status: .pending,
        createdAt: Date().addingTimeInterval(-10800), // 3 hours ago
        receiver: stranger1
    )

    static let sentRequest2 = FriendRequest(
        id: UUID(),
        senderId: currentUser.id,
        receiverId: premiumUser.id,
        status: .pending,
        createdAt: Date().addingTimeInterval(-43200), // 12 hours ago
        receiver: premiumUser
    )

    static let receivedRequests: [FriendRequest] = [
        receivedRequest1, receivedRequest2, receivedRequest3
    ]

    static let sentRequests: [FriendRequest] = [
        sentRequest1, sentRequest2
    ]

    static let allRequests: [FriendRequest] = receivedRequests + sentRequests

    // MARK: - Mock View Models

    class MockFriendsViewModel: ObservableObject {
        @Published var friends: [User] = PreviewData.friends
        @Published var receivedRequests: [FriendRequest] = PreviewData.receivedRequests
        @Published var sentRequests: [FriendRequest] = PreviewData.sentRequests
        @Published var searchResults: [User] = []
        @Published var isLoading = false
        @Published var errorMessage: String?

        func loadFriends() async {
            // Mock implementation
            isLoading = true
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isLoading = false
        }

        func searchUsers(query: String) async {
            searchResults = PreviewData.allUsers.filter {
                $0.username!.localizedCaseInsensitiveContains(query)
            }
        }

        func sendFriendRequest(to user: User) async {
            // Mock implementation
        }

        func acceptRequest(_ request: FriendRequest) async {
            receivedRequests.removeAll { $0.id == request.id }
            if let sender = request.sender {
                friends.append(sender)
            }
        }

        func rejectRequest(_ request: FriendRequest) async {
            receivedRequests.removeAll { $0.id == request.id }
        }

        func cancelRequest(_ request: FriendRequest) async {
            sentRequests.removeAll { $0.id == request.id }
        }

        func removeFriend(_ friend: User) async {
            friends.removeAll { $0.id == friend.id }
        }
    }

    // MARK: - Scenarios

    struct Scenarios {
        /// User with many friends (near limit)
        static let userNearFriendLimit = User(
            id: UUID(),
            username: "popular_user",
            email: "popular@example.com",
            totalRuns: 50,
            totalDistanceMeters: 150000,
            topSpeedMs: 21.0,
            subscriptionTier: .free,
            maxFriendsLimit: 20
        )

        /// Generate 18 friends (near 20 limit)
        static let manyFriends: [User] = (1...18).map { i in
            User(
                id: UUID(),
                username: "friend_\(i)",
                email: "friend\(i)@example.com",
                totalRuns: Int.random(in: 5...100),
                totalDistanceMeters: Double.random(in: 10000...300000),
                topSpeedMs: Double.random(in: 15...30)
            )
        }

        /// User with no friends (empty state)
        static let newUser = User(
            id: UUID(),
            username: "new_user",
            email: "new@example.com",
            totalRuns: 0,
            totalDistanceMeters: 0,
            topSpeedMs: 0,
            subscriptionTier: .free,
            maxFriendsLimit: 20
        )

        /// User at friend limit
        static let userAtLimit = User(
            id: UUID(),
            username: "maxed_user",
            email: "maxed@example.com",
            totalRuns: 100,
            totalDistanceMeters: 300000,
            topSpeedMs: 25.0,
            subscriptionTier: .free,
            maxFriendsLimit: 20
        )
    }
}
#endif

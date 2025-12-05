//
//  FriendService.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/12/2025.
//

import Foundation
import Supabase

class FriendsService {
    static let shared = FriendsService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - User Search

    /// Search for users by username
    func searchUsers(query: String, excludeUserId: UUID? = nil) async throws
        -> [User]
    {
        let users: [User] =
            try await client
            .from("users")
            .select()
            .ilike("username", pattern: "%\(query)%")
            .limit(25)  // Fetch extra in case we need to filter
            .execute()
            .value

        // Exclude current user from results if specified
        if let excludeUserId = excludeUserId {
            return users.filter { $0.id != excludeUserId }
        }

        return users
    }

    /// Get a specific user by ID
    func getUser(userId: UUID) async throws -> User {
        let user: User =
            try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Friend Requests

    /// Send a friend request to another user
    //    func sendFriendRequest(from senderId: UUID, to receiverId: UUID) async throws {
    //        struct FriendRequestInsert: Encodable {
    //            let sender_id: UUID
    //            let receiver_id: UUID
    //            let status: String
    //        }
    //
    //        let request = FriendRequestInsert(
    //            sender_id: senderId,
    //            receiver_id: receiverId,
    //            status: "pending"
    //        )
    //
    //        try await client
    //            .from("friend_requests")
    //            .insert(request)
    //            .execute()
    //    }
    // MARK: - Friend Requests
    /// Send a friend request to another user
    /// This will automatically handle re-sending after rejection
    /// - Throws: FriendRequestError with user-friendly messages
    func sendFriendRequest(from senderId: UUID, to receiverId: UUID) async throws {
        struct SendFriendRequestParams: Encodable {
            let p_receiver_id: UUID
        }

        let params = SendFriendRequestParams(p_receiver_id: receiverId)

        do {
            // Call the database function which handles re-sending logic
            try await client
                .rpc("send_friend_request", params: params)
                .execute()
        } catch {
            // Convert database errors to user-friendly errors
            throw FriendRequestError.from(error)
        }
    }

    /// Get all pending friend requests received by current user
    func getReceivedFriendRequests(userId: UUID) async throws -> [FriendRequest]
    {

        struct FriendRequestResponse: Decodable {
            let id: UUID
            let sender_id: UUID
            let receiver_id: UUID
            let status: String
            let created_at: Date
            let updated_at: Date
            let sender: User
        }

        let response: [FriendRequestResponse] =
            try await client
            .from("friend_requests")
            .select("*, sender:users!sender_id(*)")
            .eq("receiver_id", value: userId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        print(response)

        return response.map { response in
            FriendRequest(
                id: response.id,
                senderId: response.sender_id,
                receiverId: response.receiver_id,
                status: FriendRequestStatus(rawValue: response.status)
                    ?? .pending,
                createdAt: response.created_at,
                updatedAt: response.updated_at,
                sender: response.sender
            )
        }
    }

    /// Get all pending friend requests sent by current user
    func getSentFriendRequests(userId: UUID) async throws -> [FriendRequest] {

        struct FriendRequestResponse: Decodable {
            let id: UUID
            let sender_id: UUID
            let receiver_id: UUID
            let status: String
            let created_at: Date
            let updated_at: Date
            let receiver: User
        }

        let response: [FriendRequestResponse] =
            try await client
            .from("friend_requests")
            .select("*, receiver:users!receiver_id(*)")
            .eq("sender_id", value: userId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map { response in
            FriendRequest(
                id: response.id,
                senderId: response.sender_id,
                receiverId: response.receiver_id,
                status: FriendRequestStatus(rawValue: response.status)
                    ?? .pending,
                createdAt: response.created_at,
                updatedAt: response.updated_at,
                receiver: response.receiver
            )
        }
    }

    /// Accept a friend request
    func acceptFriendRequest(requestId: UUID) async throws {
        struct FriendRequestUpdate: Encodable {
            let status: String
            let updated_at: String
        }

        let update = FriendRequestUpdate(
            status: "accepted",
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("friend_requests")
            .update(update)
            .eq("id", value: requestId)
            .execute()

        // Note: Trigger will automatically create friendship records
    }

    /// Reject a friend request
    func rejectFriendRequest(requestId: UUID) async throws {
        struct FriendRequestUpdate: Encodable {
            let status: String
            let updated_at: String
        }

        let update = FriendRequestUpdate(
            status: "rejected",
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("friend_requests")
            .update(update)
            .eq("id", value: requestId)
            .execute()
    }

    /// Cancel a sent friend request
    func cancelFriendRequest(requestId: UUID) async throws {
        try await client
            .from("friend_requests")
            .delete()
            .eq("id", value: requestId)
            .execute()
    }

    /// Check if a friend request exists between two users
    func getFriendRequestStatus(from senderId: UUID, to receiverId: UUID)
        async throws -> FriendRequestStatus?
    {
        let requests: [FriendRequest] =
            try await client
            .from("friend_requests")
            .select()
            .eq("sender_id", value: senderId)
            .eq("receiver_id", value: receiverId)
            .execute()
            .value

        return requests.first?.status
    }

    // MARK: - Friendships

    /// Get all friends for a user
    func getFriends(userId: UUID) async throws -> [User] {
        struct FriendshipResponse: Decodable {
            let id: UUID
            let user_id: UUID
            let friend_id: UUID
            let created_at: Date
            let friend: User
        }

        let response: [FriendshipResponse] =
            try await client
            .from("friendships")
            .select("*, friend:users!friend_id(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map { $0.friend }
    }

    /// Get friendships with full details (including when they became friends)
    func getFriendshipsWithDetails(userId: UUID) async throws -> [Friendship] {
        struct FriendshipResponse: Decodable {
            let id: UUID
            let user_id: UUID
            let friend_id: UUID
            let created_at: Date
            let friend: User
        }

        let response =
            try await client
            .from("friendships")
            .select("*, friend:users!friend_id(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        let decoded = try JSONDecoder.supabase.decode(
            [FriendshipResponse].self,
            from: response.data
        )

        return decoded.map { response in
            Friendship(
                id: response.id,
                userId: response.user_id,
                friendId: response.friend_id,
                createdAt: response.created_at,
                friend: response.friend
            )
        }
    }

    /// Get friend count for a user
    func getFriendCount(userId: UUID) async throws -> Int {
        let friendships: [Friendship] =
            try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return friendships.count
    }

    /// Check if two users are friends
    func areFriends(userId: UUID, friendId: UUID) async throws -> Bool {
        let friendships: [Friendship] =
            try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId)
            .eq("friend_id", value: friendId)
            .execute()
            .value

        return !friendships.isEmpty
    }

    /// Remove a friend (unfriend)
    func removeFriend(userId: UUID, friendId: UUID) async throws {
        // Delete both directions of friendship
        try await client
            .from("friendships")
            .delete()
            .or(
                "and(user_id.eq.\(userId.uuidString),friend_id.eq.\(friendId.uuidString)),and(user_id.eq.\(friendId.uuidString),friend_id.eq.\(userId.uuidString))"
            )
            .execute()
    }

    // MARK: - Combined Status Check

    /// Get the relationship status between current user and another user
    func getRelationshipStatus(currentUserId: UUID, otherUserId: UUID)
        async throws -> RelationshipStatus
    {
        // Check if friends
        let isFriend = try await areFriends(
            userId: currentUserId,
            friendId: otherUserId
        )
        if isFriend {
            return .friends
        }

        // Check if there's a pending request from current user
        if let status = try await getFriendRequestStatus(
            from: currentUserId,
            to: otherUserId
        ) {
            if status.isPending {
                return .requestSent
            }
        }

        // Check if there's a pending request to current user
        if let status = try await getFriendRequestStatus(
            from: otherUserId,
            to: currentUserId
        ) {
            if status.isPending {
                return .requestReceived
            }
        }

        return .none
    }
}

// MARK: - Relationship Status Enum
enum RelationshipStatus {
    case none  // No relationship
    case requestSent  // Current user sent request
    case requestReceived  // Current user received request
    case friends  // Already friends

    var displayText: String {
        switch self {
        case .none: return "Add Friend"
        case .requestSent: return "Request Sent"
        case .requestReceived: return "Accept Request"
        case .friends: return "Friends"
        }
    }
}

// MARK: - Friend Request Error Handling
enum FriendRequestError: LocalizedError {
    case alreadyPending
    case alreadyFriends
    case cannotSendToSelf
    case friendLimitReached
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .alreadyPending:
            return "Friend request already pending"
        case .alreadyFriends:
            return "You are already friends with this user"
        case .cannotSendToSelf:
            return "Cannot send friend request to yourself"
        case .friendLimitReached:
            return "Friend limit reached. Upgrade to premium for unlimited friends."
        case .unknown(let message):
            return message
        }
    }

    static func from(_ error: Error) -> FriendRequestError {
        let errorMessage = error.localizedDescription

        // Parse database error messages
        if errorMessage.contains("Friend request already pending") {
            return .alreadyPending
        } else if errorMessage.contains("already friends") {
            return .alreadyFriends
        } else if errorMessage.contains("Cannot send friend request to yourself") {
            return .cannotSendToSelf
        } else if errorMessage.contains("Friend limit reached") {
            return .friendLimitReached
        } else {
            return .unknown(errorMessage)
        }
    }
}

// MARK: - JSONDecoder Extension
extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

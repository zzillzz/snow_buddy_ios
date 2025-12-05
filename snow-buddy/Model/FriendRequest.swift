//
//  FriendRequest.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/12/2025.
//

import Foundation

// MARK: - Friend Request Status Enum
enum FriendRequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }

    var isPending: Bool {
        self == .pending
    }

    var isResolved: Bool {
        self != .pending
    }
}

// MARK: - Friend Request Model
struct FriendRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    var status: FriendRequestStatus
    let createdAt: Date
    var updatedAt: Date

    // Optional: Populated when joining with users table
    var sender: User?
    var receiver: User?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sender
        case receiver
    }

    // MARK: - Computed Properties

    /// Check if request is pending
    var isPending: Bool {
        status.isPending
    }

    /// Check if request has been resolved (accepted/rejected/cancelled)
    var isResolved: Bool {
        status.isResolved
    }

    /// Time since request was created
    var timeSinceCreated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Time since last update
    var timeSinceUpdated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        senderId: UUID,
        receiverId: UUID,
        status: FriendRequestStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sender: User? = nil,
        receiver: User? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sender = sender
        self.receiver = receiver
    }

    // MARK: - Helper Methods

    /// Check if current user is the sender
    func isSender(userId: UUID) -> Bool {
        senderId == userId
    }

    /// Check if current user is the receiver
    func isReceiver(userId: UUID) -> Bool {
        receiverId == userId
    }

    /// Get the other user's ID (not the current user)
    func getOtherUserId(from currentUserId: UUID) -> UUID? {
        if senderId == currentUserId {
            return receiverId
        } else if receiverId == currentUserId {
            return senderId
        }
        return nil
    }

    /// Check if current user can accept this request
    func canAccept(userId: UUID) -> Bool {
        isReceiver(userId: userId) && isPending
    }

    /// Check if current user can reject this request
    func canReject(userId: UUID) -> Bool {
        isReceiver(userId: userId) && isPending
    }

    /// Check if current user can cancel this request
    func canCancel(userId: UUID) -> Bool {
        isSender(userId: userId) && isPending
    }
}

// MARK: - Friend Request with User Details
/// Convenience models for different views

/// For received requests - includes sender info
struct ReceivedFriendRequest: Identifiable {
    let request: FriendRequest
    let sender: User

    var id: UUID { request.id }
    var status: FriendRequestStatus { request.status }
    var isPending: Bool { request.isPending }
    var timeSinceCreated: String { request.timeSinceCreated }

    init(request: FriendRequest, sender: User) {
        self.request = request
        self.sender = sender
    }
}

/// For sent requests - includes receiver info
struct SentFriendRequest: Identifiable {
    let request: FriendRequest
    let receiver: User

    var id: UUID { request.id }
    var status: FriendRequestStatus { request.status }
    var isPending: Bool { request.isPending }
    var timeSinceCreated: String { request.timeSinceCreated }

    init(request: FriendRequest, receiver: User) {
        self.request = request
        self.receiver = receiver
    }
}

// MARK: - Sample Data (for previews/testing)
extension FriendRequest {
    static let pendingSample = FriendRequest(
        id: UUID(),
        senderId: UUID(),
        receiverId: UUID(),
        status: .pending,
        createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
        sender: User.sample
    )

    static let acceptedSample = FriendRequest(
        id: UUID(),
        senderId: UUID(),
        receiverId: UUID(),
        status: .accepted,
        createdAt: Date().addingTimeInterval(-86400), // 1 day ago
        updatedAt: Date().addingTimeInterval(-7200), // 2 hours ago
        sender: User.premiumSample
    )

    static let rejectedSample = FriendRequest(
        id: UUID(),
        senderId: UUID(),
        receiverId: UUID(),
        status: .rejected,
        createdAt: Date().addingTimeInterval(-172800), // 2 days ago
        updatedAt: Date().addingTimeInterval(-86400)
    )
}

extension ReceivedFriendRequest {
    static let sample = ReceivedFriendRequest(
        request: .pendingSample,
        sender: User.sample
    )
}

extension SentFriendRequest {
    static let sample = SentFriendRequest(
        request: .pendingSample,
        receiver: User.premiumSample
    )
}

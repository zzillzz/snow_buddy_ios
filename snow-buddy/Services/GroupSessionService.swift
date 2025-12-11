//
//  GroupSessionService.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import Supabase

class GroupSessionService {
    static let shared = GroupSessionService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Session Lifecycle

    /// Start a new group session using RPC function (enforces one active session per group)
    func startSession(groupId: UUID, resortId: UUID) async throws -> UUID {
        struct StartSessionParams: Encodable {
            let p_group_id: UUID
            let p_resort_id: UUID
        }

        let params = StartSessionParams(
            p_group_id: groupId,
            p_resort_id: resortId
        )

        do {
            let response: UUID =
                try await client
                .rpc("start_group_session", params: params)
                .single()
                .execute()
                .value

            return response
        } catch {
            throw GroupSessionError.from(error)
        }
    }

    /// End a session
    func endSession(sessionId: UUID) async throws {
        struct SessionUpdate: Encodable {
            let status: String
            let ended_at: String
        }

        let update = SessionUpdate(
            status: "ended",
            ended_at: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("group_sessions")
            .update(update)
            .eq("id", value: sessionId)
            .execute()

        // Note: All participants will be automatically ejected via trigger
    }

    /// Get a specific session by ID
    func getSession(id: UUID) async throws -> GroupSession {
        struct SessionResponse: Decodable {
            let id: UUID
            let group_id: UUID
            let resort_id: UUID
            let started_by: UUID
            let started_at: Date
            let ended_at: Date?
            let status: String
            let resort: Resort
        }

        let response: SessionResponse =
            try await client
            .from("group_sessions")
            .select("*, resort:resorts!resort_id(*)")
            .eq("id", value: id)
            .single()
            .execute()
            .value

        let participantCount = try await getParticipantCount(sessionId: id)

        return GroupSession(
            id: response.id,
            groupId: response.group_id,
            resortId: response.resort_id,
            startedBy: response.started_by,
            startedAt: response.started_at,
            endedAt: response.ended_at,
            status: SessionStatus(rawValue: response.status) ?? .active,
            resort: response.resort,
            participantCount: participantCount
        )
    }

    /// Get active session for a group
    func getActiveSession(groupId: UUID) async throws -> GroupSession? {
        struct SessionResponse: Decodable {
            let id: UUID
            let group_id: UUID
            let resort_id: UUID
            let started_by: UUID
            let started_at: Date
            let ended_at: Date?
            let status: String
            let resort: Resort
        }

        let response: [SessionResponse] =
            try await client
            .from("group_sessions")
            .select("*, resort:resorts!resort_id(*)")
            .eq("group_id", value: groupId)
            .eq("status", value: "active")
            .limit(1)
            .execute()
            .value

        guard let sessionData = response.first else { return nil }

        let participantCount = try await getParticipantCount(
            sessionId: sessionData.id)

        return GroupSession(
            id: sessionData.id,
            groupId: sessionData.group_id,
            resortId: sessionData.resort_id,
            startedBy: sessionData.started_by,
            startedAt: sessionData.started_at,
            endedAt: sessionData.ended_at,
            status: SessionStatus(rawValue: sessionData.status) ?? .active,
            resort: sessionData.resort,
            participantCount: participantCount
        )
    }

    /// Get session history for a group
    func getSessionHistory(
        groupId: UUID,
        limit: Int = 20
    ) async throws -> [GroupSession] {
        struct SessionResponse: Decodable {
            let id: UUID
            let group_id: UUID
            let resort_id: UUID
            let started_by: UUID
            let started_at: Date
            let ended_at: Date?
            let status: String
            let resort: Resort
        }

        let response: [SessionResponse] =
            try await client
            .from("group_sessions")
            .select("*, resort:resorts!resort_id(*)")
            .eq("group_id", value: groupId)
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return try await withThrowingTaskGroup(
            of: (Int, GroupSession).self
        ) { group in
            for (index, session) in response.enumerated() {
                group.addTask {
                    let count = try await self.getParticipantCount(
                        sessionId: session.id)

                    return (
                        index,
                        GroupSession(
                            id: session.id,
                            groupId: session.group_id,
                            resortId: session.resort_id,
                            startedBy: session.started_by,
                            startedAt: session.started_at,
                            endedAt: session.ended_at,
                            status: SessionStatus(rawValue: session.status)
                                ?? .active,
                            resort: session.resort,
                            participantCount: count
                        )
                    )
                }
            }

            var sessions: [(Int, GroupSession)] = []
            for try await result in group {
                sessions.append(result)
            }

            return sessions.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // MARK: - Session Participants

    /// Join a session
    func joinSession(sessionId: UUID, userId: UUID) async throws {
        struct JoinParams: Encodable {
            let session_id: UUID
            let user_id: UUID
            let joined_at: String
        }

        let params = JoinParams(
            session_id: sessionId,
            user_id: userId,
            joined_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await client
                .from("session_participants")
                .insert(params)
                .execute()
        } catch {
            throw GroupSessionError.from(error)
        }
    }

    /// Leave a session
    func leaveSession(sessionId: UUID, userId: UUID) async throws {
        struct LeaveUpdate: Encodable {
            let left_at: String
            let is_sharing_location: Bool
        }

        let update = LeaveUpdate(
            left_at: ISO8601DateFormatter().string(from: Date()),
            is_sharing_location: false
        )

        try await client
            .from("session_participants")
            .update(update)
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Update location sharing status
    func updateLocationSharingStatus(
        sessionId: UUID,
        userId: UUID,
        isSharing: Bool
    ) async throws {
        struct SharingUpdate: Encodable {
            let is_sharing_location: Bool
            let last_location_update: String?
        }

        let update = SharingUpdate(
            is_sharing_location: isSharing,
            last_location_update: isSharing
                ? ISO8601DateFormatter().string(from: Date()) : nil
        )

        try await client
            .from("session_participants")
            .update(update)
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Get all participants in a session
    func getSessionParticipants(sessionId: UUID) async throws
        -> [SessionParticipant]
    {
        struct ParticipantResponse: Decodable {
            let id: UUID
            let session_id: UUID
            let user_id: UUID
            let joined_at: Date
            let left_at: Date?
            let is_sharing_location: Bool
            let last_location_update: Date?
            let user: User
        }

        let response: [ParticipantResponse] =
            try await client
            .from("session_participants")
            .select("*, user:users!user_id(*)")
            .eq("session_id", value: sessionId)
            .order("joined_at", ascending: true)
            .execute()
            .value

        return response.map { r in
            SessionParticipant(
                id: r.id,
                sessionId: r.session_id,
                userId: r.user_id,
                joinedAt: r.joined_at,
                leftAt: r.left_at,
                isSharingLocation: r.is_sharing_location,
                lastLocationUpdate: r.last_location_update,
                user: r.user
            )
        }
    }

    /// Get active participants (not left)
    func getActiveParticipants(sessionId: UUID) async throws
        -> [SessionParticipant]
    {
        struct ParticipantResponse: Decodable {
            let id: UUID
            let session_id: UUID
            let user_id: UUID
            let joined_at: Date
            let left_at: Date?
            let is_sharing_location: Bool
            let last_location_update: Date?
            let user: User
        }

        let response: [ParticipantResponse] =
            try await client
            .from("session_participants")
            .select("*, user:users!user_id(*)")
            .eq("session_id", value: sessionId)
            .is("left_at", value: nil)
            .order("joined_at", ascending: true)
            .execute()
            .value

        return response.map { r in
            SessionParticipant(
                id: r.id,
                sessionId: r.session_id,
                userId: r.user_id,
                joinedAt: r.joined_at,
                leftAt: r.left_at,
                isSharingLocation: r.is_sharing_location,
                lastLocationUpdate: r.last_location_update,
                user: r.user
            )
        }
    }

    /// Get participant count for a session
    func getParticipantCount(sessionId: UUID) async throws -> Int {
        let participants: [SessionParticipant] =
            try await client
            .from("session_participants")
            .select()
            .eq("session_id", value: sessionId)
            .is("left_at", value: nil)
            .execute()
            .value

        return participants.count
    }

    /// Check if user is participating in a session
    func isParticipating(sessionId: UUID, userId: UUID) async throws -> Bool {
        let participants: [SessionParticipant] =
            try await client
            .from("session_participants")
            .select()
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .is("left_at", value: nil)
            .execute()
            .value

        return !participants.isEmpty
    }

    // MARK: - Location Shares (Premium Feature)

    /// Save location share to database (for history)
    func saveLocationShare(
        sessionId: UUID,
        userId: UUID,
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        speedMs: Double?,
        batteryLevel: Int?
    ) async throws {
        struct LocationShare: Encodable {
            let session_id: UUID
            let user_id: UUID
            let latitude: Double
            let longitude: Double
            let altitude: Double?
            let speed_ms: Double?
            let battery_level: Int?
            let timestamp: String
        }

        let share = LocationShare(
            session_id: sessionId,
            user_id: userId,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            speed_ms: speedMs,
            battery_level: batteryLevel,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("location_shares")
            .insert(share)
            .execute()

        // Also update last_location_update in session_participants
        try await updateLastLocationUpdate(sessionId: sessionId, userId: userId)
    }

    /// Update last location update timestamp
    private func updateLastLocationUpdate(sessionId: UUID, userId: UUID)
        async throws
    {
        struct LocationUpdate: Encodable {
            let last_location_update: String
        }

        let update = LocationUpdate(
            last_location_update: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("session_participants")
            .update(update)
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Get location history for a session (Premium feature)
    func getLocationHistory(
        sessionId: UUID,
        userId: UUID? = nil,
        limit: Int = 1000
    ) async throws -> [LocationShareRecord] {
        struct LocationShareResponse: Decodable {
            let id: UUID
            let session_id: UUID
            let user_id: UUID
            let latitude: Double
            let longitude: Double
            let altitude: Double?
            let speed_ms: Double?
            let battery_level: Int?
            let timestamp: Date
        }

        var query = client
            .from("location_shares")
            .select()
            .eq("session_id", value: sessionId)

        if let userId = userId {
            query = query.eq("user_id", value: userId)
        }

        let response: [LocationShareResponse] =
            try await query
            .order("timestamp", ascending: true)
            .limit(limit)
            .execute()
            .value

        return response.map { r in
            LocationShareRecord(
                id: r.id,
                sessionId: r.session_id,
                userId: r.user_id,
                latitude: r.latitude,
                longitude: r.longitude,
                altitude: r.altitude,
                speedMs: r.speed_ms,
                batteryLevel: r.battery_level,
                timestamp: r.timestamp
            )
        }
    }

    // MARK: - Auto-Cleanup

    /// Check and end sessions that should auto-end (12 hours inactive)
    func checkAndEndStaleSessions() async throws -> [UUID] {
        struct SessionResponse: Decodable {
            let id: UUID
            let started_at: Date
        }

        let activeSessions: [SessionResponse] =
            try await client
            .from("group_sessions")
            .select("id, started_at")
            .eq("status", value: "active")
            .execute()
            .value

        let now = Date()
        let maxDuration: TimeInterval = 12 * 3600  // 12 hours

        var endedSessionIds: [UUID] = []

        for session in activeSessions {
            let duration = now.timeIntervalSince(session.started_at)
            if duration >= maxDuration {
                try await endSession(sessionId: session.id)
                endedSessionIds.append(session.id)
            }
        }

        return endedSessionIds
    }
}

// MARK: - Location Share Record Model
struct LocationShareRecord: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let userId: UUID
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speedMs: Double?
    let batteryLevel: Int?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case latitude
        case longitude
        case altitude
        case speedMs = "speed_ms"
        case batteryLevel = "battery_level"
        case timestamp
    }
}

// MARK: - Group Session Error Handling
enum GroupSessionError: LocalizedError {
    case sessionAlreadyActive
    case sessionNotFound
    case notGroupMember
    case alreadyParticipating
    case sessionEnded
    case notAuthorized
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            return "This group already has an active session"
        case .sessionNotFound:
            return "Session not found"
        case .notGroupMember:
            return "You must be a group member to join this session"
        case .alreadyParticipating:
            return "You are already in this session"
        case .sessionEnded:
            return "This session has ended"
        case .notAuthorized:
            return "You don't have permission to perform this action"
        case .unknown(let message):
            return message
        }
    }

    static func from(_ error: Error) -> GroupSessionError {
        let errorMessage = error.localizedDescription

        // Parse database error messages
        if errorMessage.contains("already has an active session") {
            return .sessionAlreadyActive
        } else if errorMessage.contains("not found") {
            return .sessionNotFound
        } else if errorMessage.contains("not a member") {
            return .notGroupMember
        } else if errorMessage.contains("already participating") {
            return .alreadyParticipating
        } else if errorMessage.contains("session has ended") {
            return .sessionEnded
        } else if errorMessage.contains("not authorized")
            || errorMessage.contains("permission")
        {
            return .notAuthorized
        } else {
            return .unknown(errorMessage)
        }
    }
}

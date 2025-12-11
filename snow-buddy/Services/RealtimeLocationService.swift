//
//  RealtimeLocationService.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import Supabase
import CoreLocation

/// Service for managing real-time location sharing via Supabase Realtime Presence
@MainActor
class RealtimeLocationService: ObservableObject {
    @Published var participants: [ParticipantLocation] = []
    @Published var isConnected = false
    @Published var connectionError: String?

    private var channel: RealtimeChannelV2?
    private var sessionId: UUID?
    private var currentUserId: UUID?
    private var presenceTask: Task<Void, Never>?

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    // MARK: - Channel Management

    /// Join a session's realtime channel
    func joinSession(_ sessionId: UUID, userId: UUID, username: String)
        async throws
    {
        // Leave current channel if any
        await leaveSession()

        self.sessionId = sessionId
        self.currentUserId = userId

        // Create channel for this session
        let channelId = "group_session:\(sessionId.uuidString)"

        do {
            channel = client.realtimeV2.channel(channelId)

            guard let channel = channel else {
                throw RealtimeLocationError.connectionFailed("Failed to create channel")
            }

            // Subscribe to channel first
            try await channel.subscribeWithError()

            // Start listening to presence changes
            startListeningToPresence(channel: channel)

            isConnected = true
            connectionError = nil

            print("✅ Joined realtime channel: \(channelId)")

        } catch {
            isConnected = false
            connectionError = error.localizedDescription
            print("❌ Failed to join channel: \(error)")
            throw RealtimeLocationError.connectionFailed(error.localizedDescription)
        }
    }

    /// Start listening to presence changes using AsyncStream
    private func startListeningToPresence(channel: RealtimeChannelV2) {
        presenceTask = Task { [weak self] in
            guard let self = self else { return }

            let presenceStream = channel.presenceChange()

            for await presence in presenceStream {
                await self.handlePresenceChange(presence)
            }
        }
    }

    /// Leave the current session's channel
    func leaveSession() async {
        // Cancel presence listening task
        presenceTask?.cancel()
        presenceTask = nil

        guard let channel = channel else { return }

        do {
            await channel.unsubscribe()
            self.channel = nil
            self.sessionId = nil
            self.currentUserId = nil
            self.participants = []
            self.isConnected = false

            print("✅ Left realtime channel")
        } catch {
            print("❌ Error leaving channel: \(error)")
        }
    }

    // MARK: - Location Updates

    /// Publish current location to the channel
    func updateLocation(
        _ location: CLLocation,
        userId: UUID,
        username: String,
        batteryLevel: Int
    ) async {
        guard channel != nil else {
            print("⚠️ Cannot update location: Not connected to channel")
            return
        }

        let presenceState: JSONObject = [
            "user_id": .string(userId.uuidString),
            "username": .string(username),
            "latitude": .double(location.coordinate.latitude),
            "longitude": .double(location.coordinate.longitude),
            "altitude": .double(location.altitude),
            "speed_ms": .double(location.speed >= 0 ? location.speed : 0),
            "battery_level": .double(Double(batteryLevel)),
            "last_update": .string(ISO8601DateFormatter().string(from: Date())),
            "is_online": .bool(true),
        ]

        do {
            try await channel?.track(presenceState)
            print("📍 Location updated: \(location.coordinate)")
        } catch {
            print("❌ Failed to update location: \(error)")
        }
    }

    /// Mark user as offline (while staying in channel)
    func markOffline() async {
        guard let userId = currentUserId,
            let username = participants.first(where: { $0.id == userId })?
                .username
        else { return }

        let presenceState: JSONObject = [
            "user_id": .string(userId.uuidString),
            "username": .string(username),
            "is_online": .bool(false),
        ]

        try? await channel?.track(presenceState)
    }

    // MARK: - Presence Event Handlers

    /// Handle presence changes from the AsyncStream
    private func handlePresenceChange(_ action: PresenceAction) async {
        print("🔄 Presence change - Joins: \(action.joins.count), Leaves: \(action.leaves.count)")

        // Handle joins - users who just came online
        for (_, presenceV2) in action.joins {
            if let participant = parsePresence(presenceV2) {
                // Add or update participant
                if let index = participants.firstIndex(where: { $0.id == participant.id }) {
                    participants[index] = participant
                } else {
                    participants.append(participant)
                }
                print("👋 User joined: \(participant.username)")
            }
        }

        // Handle leaves - users who went offline
        for (_, presenceV2) in action.leaves {
            if let participant = parsePresence(presenceV2) {
                // Mark as offline instead of removing
                if let index = participants.firstIndex(where: { $0.id == participant.id }) {
                    let updated = participants[index]
                    let offlineParticipant = ParticipantLocation(
                        id: updated.id,
                        username: updated.username,
                        latitude: updated.latitude,
                        longitude: updated.longitude,
                        altitude: updated.altitude,
                        speedMs: updated.speedMs,
                        batteryLevel: updated.batteryLevel,
                        lastUpdate: updated.lastUpdate,
                        isOnline: false
                    )
                    participants[index] = offlineParticipant
                    print("👋 User left: \(participant.username)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Parse presence data into ParticipantLocation
    private func parsePresence(_ presence: PresenceV2) -> ParticipantLocation? {
        let state = presence.state

        // Extract required fields from AnyJSON
        guard case .string(let userIdStr) = state["user_id"],
              let userId = UUID(uuidString: userIdStr),
              case .string(let username) = state["username"],
              case .double(let latitude) = state["latitude"],
              case .double(let longitude) = state["longitude"]
        else {
            print("⚠️ Failed to parse required presence fields")
            return nil
        }

        // Extract optional fields
        var altitude: Double?
        if case .double(let alt) = state["altitude"] {
            altitude = alt
        }

        var speedMs: Double?
        if case .double(let speed) = state["speed_ms"] {
            speedMs = speed
        }

        var batteryLevel: Int?
        if case .double(let battery) = state["battery_level"] {
            batteryLevel = Int(battery)
        }

        var lastUpdate = Date()
        if case .string(let lastUpdateStr) = state["last_update"],
           let date = ISO8601DateFormatter().date(from: lastUpdateStr)
        {
            lastUpdate = date
        }

        var isOnline = true
        if case .bool(let online) = state["is_online"] {
            isOnline = online
        }

        return ParticipantLocation(
            id: userId,
            username: username,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            speedMs: speedMs,
            batteryLevel: batteryLevel,
            lastUpdate: lastUpdate,
            isOnline: isOnline
        )
    }

    /// Get participant by user ID
    func getParticipant(userId: UUID) -> ParticipantLocation? {
        participants.first(where: { $0.id == userId })
    }

    /// Get all online participants
    func getOnlineParticipants() -> [ParticipantLocation] {
        participants.filter { $0.isOnline }
    }

    /// Get participants currently sharing location (moving or recently updated)
    func getSharingParticipants() -> [ParticipantLocation] {
        participants.filter { participant in
            guard participant.isOnline else { return false }
            // Consider fresh if updated within last 2 minutes
            let timeSinceUpdate = Date().timeIntervalSince(
                participant.lastUpdate)
            return timeSinceUpdate < 120
        }
    }

    // MARK: - Connection State

    /// Manually reconnect to channel (after network interruption)
    func reconnect() async throws {
        guard let sessionId = sessionId, let userId = currentUserId else {
            throw RealtimeLocationError.notConnected
        }

        // Get username from current participants or use a default
        let username =
            participants.first(where: { $0.id == userId })?.username ?? "User"

        try await joinSession(sessionId, userId: userId, username: username)
    }

    /// Check if currently connected to a session
    var isInSession: Bool {
        channel != nil && isConnected
    }
}

// MARK: - Realtime Location Error Handling
enum RealtimeLocationError: LocalizedError {
    case connectionFailed(String)
    case notConnected
    case invalidPresenceData
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .notConnected:
            return "Not connected to any session"
        case .invalidPresenceData:
            return "Invalid presence data received"
        case .unknown(let message):
            return message
        }
    }
}

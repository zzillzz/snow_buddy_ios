//
//  GroupSessionViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import Supabase
import CoreLocation
import Combine

@MainActor
class GroupSessionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var session: GroupSession?
    @Published var participants: [ParticipantLocation] = []
    @Published var sessionParticipants: [SessionParticipant] = []
    @Published var isSharingLocation = false
    @Published var isLoading = false
    @Published var alertConfig: AlertConfig?

    // Location sharing state
    @Published var batteryLevel: Int = 100
    @Published var isBatteryLow = false
    @Published var currentInterval: TimeInterval = 60
    @Published var lastUpdateTime: Date?

    // MARK: - Private Properties

    private let sessionService = GroupSessionService.shared
    private let realtimeService = RealtimeLocationService()
    private var locationSharingService: LocationSharingService?
    private let trackingManager: TrackingManager

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(trackingManager: TrackingManager) {
        self.trackingManager = trackingManager

        // Initialize location sharing service
        self.locationSharingService = LocationSharingService(
            trackingManager: trackingManager,
            realtimeService: realtimeService,
            sessionService: sessionService
        )

        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to realtime participants updates
        realtimeService.$participants
            .assign(to: &$participants)

        // Subscribe to location sharing service state
        locationSharingService?.$isSharingLocation
            .assign(to: &$isSharingLocation)

        locationSharingService?.$batteryLevel
            .assign(to: &$batteryLevel)

        locationSharingService?.$isBatteryLow
            .assign(to: &$isBatteryLow)

        locationSharingService?.$currentInterval
            .assign(to: &$currentInterval)

        locationSharingService?.$lastUpdateTime
            .assign(to: &$lastUpdateTime)

        // Subscribe to TrackingManager location updates
        trackingManager.$userLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                // Convert coordinate to CLLocation
                let location = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                self?.locationSharingService?.updateCurrentLocation(location)
            }
            .store(in: &cancellables)
    }

    // MARK: - Session Lifecycle

    /// Start a new group session
    func startSession(groupId: UUID, resortId: UUID) async throws {
        isLoading = true

        do {
            let sessionId = try await sessionService.startSession(
                groupId: groupId,
                resortId: resortId
            )

            print("✅ Session started with ID: \(sessionId)")

            // Load the session details
            session = try await sessionService.getSession(id: sessionId)

            // Connect to realtime (starter already added as participant by RPC)
            guard let user = try? await SupabaseService.shared.getAuthenticatedUser(),
                  let userId = UUID(uuidString: user.id.uuidString),
                  let username = user.email?.components(separatedBy: "@").first else {
                throw GroupSessionError.notAuthorized
            }

            // Connect to realtime channel
            try await realtimeService.joinSession(
                sessionId,
                userId: userId,
                username: username
            )

            // Load session participants
            await loadSessionParticipants(sessionId: sessionId)

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Session Started",
                    message: "Your group session has begun!"
                )
            }

            isLoading = false
        } catch let error as GroupSessionError {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: error.errorDescription ?? "Failed to start session."
                )
            }
            throw error
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to start session. Please try again."
                )
            }
            throw error
        }
    }

    /// Join an existing session
    func joinSession(_ sessionId: UUID) async throws {
        guard let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString),
              let username = user.email?.components(separatedBy: "@").first else {
            throw GroupSessionError.notAuthorized
        }

        isLoading = true

        do {
            // Join session in database
            try await sessionService.joinSession(sessionId: sessionId, userId: userId)

            // Connect to realtime channel
            try await realtimeService.joinSession(
                sessionId,
                userId: userId,
                username: username
            )

            // Load session participants
            await loadSessionParticipants(sessionId: sessionId)

            print("✅ Joined session: \(sessionId)")

            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to join session. Please try again."
                )
            }
            throw error
        }
    }

    /// Leave the current session
    func leaveSession() async {
        guard let sessionId = session?.id,
              let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString) else {
            return
        }

        isLoading = true

        do {
            // Stop location sharing first
            if isSharingLocation {
                await toggleLocationSharing()
            }

            // Leave session in database
            try await sessionService.leaveSession(sessionId: sessionId, userId: userId)

            // Disconnect from realtime channel
            await realtimeService.leaveSession()

            // Clean up location sharing service
            await locationSharingService?.cleanup()

            // Clear local state
            await MainActor.run {
                session = nil
                participants = []
                sessionParticipants = []
            }

            print("✅ Left session")

            isLoading = false
        } catch {
            isLoading = false
            print("❌ Error leaving session: \(error)")
        }
    }

    /// End the session (owner only)
    func endSession() async throws {
        guard let sessionId = session?.id else {
            throw GroupSessionError.sessionNotFound
        }

        isLoading = true

        do {
            try await sessionService.endSession(sessionId: sessionId)

            // Disconnect from realtime
            await realtimeService.leaveSession()

            // Clean up location sharing
            await locationSharingService?.cleanup()

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Session Ended",
                    message: "The group session has ended."
                )
                session = nil
                participants = []
                sessionParticipants = []
            }

            print("✅ Session ended")

            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to end session. Please try again."
                )
            }
            throw error
        }
    }

    // MARK: - Location Sharing

    /// Toggle location sharing on/off
    func toggleLocationSharing() async {
        guard let sessionId = session?.id,
              let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString),
              let username = user.email?.components(separatedBy: "@").first else {
            return
        }

        if isSharingLocation {
            // Stop sharing
            await locationSharingService?.stopSharing()
            print("🛑 Stopped location sharing")
        } else {
            // Check battery level first
            if isBatteryLow {
                await MainActor.run {
                    alertConfig = AlertConfig(
                        title: "Low Battery",
                        message: "Battery is below 20%. Location sharing may drain battery quickly."
                    )
                }
            }

            // Start sharing
            do {
                try await locationSharingService?.startSharing(
                    sessionId: sessionId,
                    userId: userId,
                    username: username
                )
                print("▶️ Started location sharing")
            } catch {
                await MainActor.run {
                    alertConfig = AlertConfig(
                        title: "Error",
                        message: "Failed to start location sharing. Please try again."
                    )
                }
            }
        }
    }

    // MARK: - Data Loading

    /// Load session details
    func loadSession(sessionId: UUID) async {
        isLoading = true

        do {
            session = try await sessionService.getSession(id: sessionId)
            await loadSessionParticipants(sessionId: sessionId)
            isLoading = false
        } catch {
            isLoading = false
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to load session details."
                )
            }
        }
    }

    /// Load session participants
    func loadSessionParticipants(sessionId: UUID) async {
        do {
            sessionParticipants = try await sessionService.getActiveParticipants(sessionId: sessionId)
        } catch {
            print("❌ Failed to load session participants: \(error)")
        }
    }

    /// Get active session for a group
    func getActiveSession(groupId: UUID) async -> GroupSession? {
        do {
            return try await sessionService.getActiveSession(groupId: groupId)
        } catch {
            print("❌ Failed to get active session: \(error)")
            return nil
        }
    }

    /// Get session history for a group
    func getSessionHistory(groupId: UUID, limit: Int = 20) async -> [GroupSession] {
        do {
            return try await sessionService.getSessionHistory(groupId: groupId, limit: limit)
        } catch {
            print("❌ Failed to get session history: \(error)")
            return []
        }
    }

    // MARK: - Helper Methods

    /// Check if current user is the session starter (can end session)
    func canEndSession() async -> Bool {
        guard let session = session,
              let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString) else {
            return false
        }

        return session.startedBy == userId
    }

    /// Get participant location by user ID
    func getParticipantLocation(userId: UUID) -> ParticipantLocation? {
        participants.first(where: { $0.id == userId })
    }

    /// Get online participants count
    var onlineParticipantsCount: Int {
        participants.filter { $0.isOnline }.count
    }

    /// Get sharing participants count
    var sharingParticipantsCount: Int {
        participants.filter { $0.isOnline && $0.isMoving }.count
    }

    /// Formatted battery impact
    var batteryImpactFormatted: String {
        locationSharingService?.batteryImpactFormatted ?? "~0% per 6h session"
    }

    /// Current sharing interval formatted
    var intervalFormatted: String {
        locationSharingService?.intervalFormatted ?? "—"
    }

    /// Location sharing status text
    var sharingStatusText: String {
        locationSharingService?.statusText ?? "Not sharing"
    }

    /// Location sharing status color
    var sharingStatusColor: String {
        locationSharingService?.statusColor ?? "gray"
    }
}

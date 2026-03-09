//
//  SessionCoordinator.swift
//  snow-buddy
//
//  Created by Claude on 1/4/2026.
//

import Foundation
import Combine

/// Coordinates group session lifecycle and state across the app
@MainActor
class SessionCoordinator: ObservableObject {
    // MARK: - Published Properties

    /// The currently active session, nil if no session
    @Published var activeSession: GroupSession?

    /// View model for the active session, nil if no session
    @Published var sessionViewModel: GroupSessionViewModel?

    /// Trigger for navigating to Map tab
    @Published var shouldNavigateToMap = false

    /// Loading state
    @Published var isLoading = false

    /// Alert configuration
    @Published var alertConfig: AlertConfig?

    // MARK: - Private Properties

    private let trackingManager: TrackingManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(trackingManager: TrackingManager) {
        self.trackingManager = trackingManager
    }

    // MARK: - Session Lifecycle

    /// Start a new group session
    func startSession(groupId: UUID, resortId: UUID) async throws {
        isLoading = true

        // Clean up any existing session first
        await cleanupSession()

        // Create new session view model
        let viewModel = GroupSessionViewModel(trackingManager: trackingManager)

        do {
            // Start the session
            try await viewModel.startSession(groupId: groupId, resortId: resortId)

            // Store view model and session
            await MainActor.run {
                self.sessionViewModel = viewModel
                self.activeSession = viewModel.session
                self.shouldNavigateToMap = true
                self.isLoading = false
                print("🗺️ SessionCoordinator: Set shouldNavigateToMap = true (start)")
            }

            // Subscribe to session updates
            setupSessionSubscriptions(viewModel: viewModel)

            print("✅ SessionCoordinator: Session started successfully")
        } catch {
            isLoading = false
            throw error
        }
    }

    /// Join an existing session
    func joinSession(_ sessionId: UUID, skipDatabaseInsert: Bool = false) async throws {
        isLoading = true

        // Clean up any existing session first
        await cleanupSession()

        // Create new session view model
        let viewModel = GroupSessionViewModel(trackingManager: trackingManager)

        do {
            // Load session details
            await viewModel.loadSession(sessionId: sessionId)

            // Get user info for realtime connection
            guard let user = try? await SupabaseService.shared.getAuthenticatedUser(),
                  let userId = UUID(uuidString: user.id.uuidString),
                  let username = user.email?.components(separatedBy: "@").first else {
                throw GroupSessionError.notAuthorized
            }

            // Try to join the session (may fail if already a participant)
            var alreadyParticipant = skipDatabaseInsert

            if skipDatabaseInsert {
                // User is already a participant, skip database insert and just connect to realtime
                print("ℹ️ User already participating, skipping database insert and reconnecting to realtime...")

                // Connect to realtime channel
                try await viewModel.realtimeService.joinSession(
                    sessionId,
                    userId: userId,
                    username: username
                )

                // Load participants
                await viewModel.loadSessionParticipants(sessionId: sessionId)
            } else {
                // Not sure if already participating, try to join
                do {
                    try await viewModel.joinSession(sessionId)
                } catch {
                    // If user is already a participant, that's fine - just continue
                    let errorString = "\(error)"
                    if errorString.contains("duplicate key") || errorString.contains("already participating") {
                        print("ℹ️ User already in session, reconnecting to realtime channel...")
                        alreadyParticipant = true

                        // Manually connect to realtime channel since joinSession failed
                        try await viewModel.realtimeService.joinSession(
                            sessionId,
                            userId: userId,
                            username: username
                        )

                        // Load participants
                        await viewModel.loadSessionParticipants(sessionId: sessionId)
                    } else {
                        throw error
                    }
                }
            }

            // Store view model and session
            await MainActor.run {
                self.sessionViewModel = viewModel
                self.activeSession = viewModel.session
                self.shouldNavigateToMap = true
                self.isLoading = false
                print("🗺️ SessionCoordinator: Set shouldNavigateToMap = true (join)")
            }

            // Subscribe to session updates
            setupSessionSubscriptions(viewModel: viewModel)

            print("✅ SessionCoordinator: \(alreadyParticipant ? "Reconnected to" : "Joined") session successfully")
        } catch {
            isLoading = false
            throw error
        }
    }

    /// Leave the current session
    func leaveSession() async {
        guard let viewModel = sessionViewModel else {
            print("⚠️ SessionCoordinator: No active session to leave")
            return
        }

        isLoading = true

        // Leave via view model
        await viewModel.leaveSession()

        // Cleanup
        await cleanupSession()

        await MainActor.run {
            self.isLoading = false
        }

        print("✅ SessionCoordinator: Left session")
    }

    /// End the current session (owner only)
    func endSession() async throws {
        guard let viewModel = sessionViewModel else {
            throw GroupSessionError.sessionNotFound
        }

        isLoading = true

        do {
            // End via view model
            try await viewModel.endSession()

            // Cleanup
            await cleanupSession()

            await MainActor.run {
                self.isLoading = false
            }

            print("✅ SessionCoordinator: Session ended")
        } catch {
            isLoading = false
            throw error
        }
    }

    // MARK: - Private Methods

    /// Set up subscriptions to session view model
    private func setupSessionSubscriptions(viewModel: GroupSessionViewModel) {
        // Subscribe to session changes
        viewModel.$session
            .assign(to: &$activeSession)

        // Subscribe to alert config
        viewModel.$alertConfig
            .compactMap { $0 }
            .assign(to: &$alertConfig)
    }

    /// Clean up current session state
    private func cleanupSession() async {
        // Cancel all subscriptions
        cancellables.removeAll()

        // Clear state
        await MainActor.run {
            self.sessionViewModel = nil
            self.activeSession = nil
        }
    }

    // MARK: - Helper Methods

    /// Check if current user can end the session
    func canEndSession() async -> Bool {
        guard let viewModel = sessionViewModel else {
            return false
        }
        return await viewModel.canEndSession()
    }

    /// Get active session for a group
    func getActiveSession(groupId: UUID) async -> GroupSession? {
        guard let viewModel = sessionViewModel else {
            // Create temporary view model to check
            let tempViewModel = GroupSessionViewModel(trackingManager: trackingManager)
            return await tempViewModel.getActiveSession(groupId: groupId)
        }
        return await viewModel.getActiveSession(groupId: groupId)
    }
}

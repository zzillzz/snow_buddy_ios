//
//  LocationSharingService.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import CoreLocation
import Combine
import UIKit

/// Service for managing location sharing with adaptive throttling
@MainActor
class LocationSharingService: ObservableObject {
    @Published var isSharingLocation = false
    @Published var lastUpdateTime: Date?
    @Published var currentInterval: TimeInterval = 60  // Default 1 minute

    private var trackingManager: TrackingManager
    private var realtimeService: RealtimeLocationService
    private var sessionService: GroupSessionService

    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateTimer: Timer?
    private var currentLocation: CLLocation?

    // Session context
    private var currentSessionId: UUID?
    private var currentUserId: UUID?
    private var currentUsername: String?

    // Battery monitoring
    @Published var batteryLevel: Int = 100
    @Published var isBatteryLow = false

    // MARK: - Initialization

    init(
        trackingManager: TrackingManager,
        realtimeService: RealtimeLocationService,
        sessionService: GroupSessionService = .shared
    ) {
        self.trackingManager = trackingManager
        self.realtimeService = realtimeService
        self.sessionService = sessionService

        setupBatteryMonitoring()
    }

    // MARK: - Location Sharing Control

    /// Start sharing location for a session
    func startSharing(
        sessionId: UUID,
        userId: UUID,
        username: String
    ) async throws {
        self.currentSessionId = sessionId
        self.currentUserId = userId
        self.currentUsername = username

        // Update sharing status in database
        try await sessionService.updateLocationSharingStatus(
            sessionId: sessionId,
            userId: userId,
            isSharing: true
        )

        isSharingLocation = true
        startLocationUpdateTimer()

        print("✅ Started location sharing for session: \(sessionId)")
    }

    /// Stop sharing location
    func stopSharing() async {
        guard let sessionId = currentSessionId,
            let userId = currentUserId
        else { return }

        // Update sharing status in database
        try? await sessionService.updateLocationSharingStatus(
            sessionId: sessionId,
            userId: userId,
            isSharing: false
        )

        isSharingLocation = false
        stopLocationUpdateTimer()
        lastUpdateTime = nil

        print("✅ Stopped location sharing")
    }

    /// Update current location (called by external location updates)
    func updateCurrentLocation(_ location: CLLocation) {
        self.currentLocation = location

        // If sharing, check if we should publish update
        if isSharingLocation {
            checkAndPublishUpdate()
        }
    }

    // MARK: - Location Update Logic

    private func startLocationUpdateTimer() {
        // Start a timer that checks for updates periodically
        locationUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndPublishUpdate()
            }
        }
    }

    private func stopLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }

    private func checkAndPublishUpdate() {
        guard isSharingLocation,
            let location = currentLocation,
            shouldPublishUpdate()
        else { return }

        Task {
            await publishLocation(location)
        }
    }

    private func shouldPublishUpdate() -> Bool {
        guard let lastUpdate = lastUpdateTime else {
            return true  // First update
        }

        let elapsed = Date().timeIntervalSince(lastUpdate)
        let adaptiveInterval = calculateAdaptiveInterval()

        return elapsed >= adaptiveInterval
    }

    private func publishLocation(_ location: CLLocation) async {
        guard let userId = currentUserId,
            let username = currentUsername
        else { return }

        // Publish to realtime channel
        await realtimeService.updateLocation(
            location,
            userId: userId,
            username: username,
            batteryLevel: batteryLevel
        )

        // Save to database for history (Premium feature)
        if let sessionId = currentSessionId {
            try? await sessionService.saveLocationShare(
                sessionId: sessionId,
                userId: userId,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                speedMs: location.speed >= 0 ? location.speed : nil,
                batteryLevel: batteryLevel
            )
        }

        lastUpdateTime = Date()
        currentInterval = calculateAdaptiveInterval()

        print(
            "📍 Published location update (interval: \(Int(currentInterval))s)"
        )
    }

    // MARK: - Adaptive Interval Calculation

    private func calculateAdaptiveInterval() -> TimeInterval {
        let speed = trackingManager.currentSpeed

        // Battery-based throttling
        if isBatteryLow {
            return .infinity  // Stop sharing when battery is critical
        } else if batteryLevel < 50 {
            return calculateSpeedBasedInterval(speed) * 2  // Double intervals for low battery
        }

        return calculateSpeedBasedInterval(speed)
    }

    private func calculateSpeedBasedInterval(_ speed: Double) -> TimeInterval {
        // Speed is in m/s
        if speed < 1.0 {
            // Stationary: 3 minutes
            return 180
        } else if speed > 10.0 {
            // Fast (> 36 km/h): 30 seconds
            return 30
        } else {
            // Moving normally: 1 minute
            return 60
        }
    }

    // MARK: - Battery Monitoring

    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        // Update battery level immediately
        updateBatteryLevel()

        // Monitor battery level changes
        NotificationCenter.default.publisher(
            for: UIDevice.batteryLevelDidChangeNotification
        )
        .sink { [weak self] _ in
            self?.updateBatteryLevel()
        }
        .store(in: &cancellables)

        // Monitor battery state changes (charging/unplugged)
        NotificationCenter.default.publisher(
            for: UIDevice.batteryStateDidChangeNotification
        )
        .sink { [weak self] _ in
            self?.updateBatteryLevel()
        }
        .store(in: &cancellables)
    }

    private func updateBatteryLevel() {
        let level = UIDevice.current.batteryLevel

        // batteryLevel returns -1.0 if battery monitoring is not enabled or not available
        if level >= 0 {
            batteryLevel = Int(level * 100)
        } else {
            batteryLevel = 100  // Assume full if unknown
        }

        // Check if battery is low
        let wasLow = isBatteryLow
        isBatteryLow = batteryLevel < 20

        // If battery just became low, pause sharing and notify
        if isBatteryLow && !wasLow && isSharingLocation {
            Task {
                await handleLowBattery()
            }
        }
    }

    private func handleLowBattery() async {
        print(
            "⚠️ Battery low (\(batteryLevel)%), pausing location sharing")

        // Mark as offline but don't fully stop sharing
        await realtimeService.markOffline()

        // Could show a notification to user here
    }

    // MARK: - Session Management

    /// Resume sharing when battery is sufficient
    func resumeSharingIfPossible() async {
        guard !isBatteryLow,
            isSharingLocation,
            let sessionId = currentSessionId,
            let userId = currentUserId,
            let username = currentUsername
        else { return }

        // Try to start sharing again
        try? await startSharing(
            sessionId: sessionId,
            userId: userId,
            username: username
        )

        print("✅ Resumed location sharing (battery: \(batteryLevel)%)")
    }

    /// Clean up when leaving session
    func cleanup() async {
        await stopSharing()
        currentSessionId = nil
        currentUserId = nil
        currentUsername = nil
        currentLocation = nil
    }

    // MARK: - State Properties

    /// Current sharing interval formatted
    var intervalFormatted: String {
        let minutes = Int(currentInterval / 60)
        let seconds = Int(currentInterval.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    /// Estimated battery impact percentage
    var estimatedBatteryImpact: Double {
        // Rough estimate: ~0.5% per hour for 1-min updates
        // This is additional to the base GPS drain
        let hoursPerDay = 6.0  // Typical session length
        let updatesPerHour = 3600.0 / currentInterval
        let impactPerUpdate = 0.008  // ~0.5% per hour / 60 updates

        return updatesPerHour * impactPerUpdate * hoursPerDay
    }

    /// Formatted battery impact
    var batteryImpactFormatted: String {
        String(format: "~%.1f%% per 6h session", estimatedBatteryImpact)
    }

    /// Sharing status text
    var statusText: String {
        if !isSharingLocation {
            return "Not sharing"
        } else if isBatteryLow {
            return "Paused (low battery)"
        } else if batteryLevel < 50 {
            return "Sharing (reduced frequency)"
        } else {
            return "Sharing location"
        }
    }

    /// Status color
    var statusColor: String {
        if !isSharingLocation {
            return "gray"
        } else if isBatteryLow {
            return "red"
        } else if batteryLevel < 50 {
            return "orange"
        } else {
            return "green"
        }
    }
}

// MARK: - Helper Extensions
extension LocationSharingService {
    /// Check if currently in a session
    var isInSession: Bool {
        currentSessionId != nil
    }

    /// Time since last update formatted
    var timeSinceLastUpdateFormatted: String? {
        guard let lastUpdate = lastUpdateTime else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}

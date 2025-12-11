//
//  GroupSession.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import CoreLocation

// MARK: - Session Status Enum
enum SessionStatus: String, Codable, CaseIterable {
    case active = "active"
    case ended = "ended"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .ended: return "Ended"
        }
    }

    var icon: String {
        switch self {
        case .active: return "play.circle.fill"
        case .ended: return "stop.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .active: return "green"
        case .ended: return "gray"
        }
    }
}

// MARK: - Group Session Model
struct GroupSession: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID
    let resortId: UUID
    let startedBy: UUID
    let startedAt: Date
    let endedAt: Date?
    let status: SessionStatus

    // Optional: Populated when joining with other tables
    var resort: Resort?
    var group: GroupModel?
    var participantCount: Int?
    var participants: [SessionParticipant]?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case resortId = "resort_id"
        case startedBy = "started_by"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case status
        case resort
        case group
        case participantCount = "participant_count"
        case participants
    }

    // MARK: - Computed Properties

    /// Session duration in seconds
    var duration: TimeInterval {
        if let ended = endedAt {
            return ended.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    /// Formatted session duration (e.g., "2h 30m")
    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Short duration format (e.g., "2:30")
    var durationShort: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    /// Is session currently active
    var isActive: Bool {
        status == .active
    }

    /// Is session ended
    var isEnded: Bool {
        status == .ended
    }

    /// Formatted start time
    var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    /// Formatted start date
    var startDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startedAt)
    }

    /// Formatted end time
    var endTimeFormatted: String? {
        guard let ended = endedAt else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: ended)
    }

    /// Full session time range (e.g., "9:00 AM - 3:30 PM")
    var timeRangeFormatted: String {
        if let endTime = endTimeFormatted {
            return "\(startTimeFormatted) - \(endTime)"
        }
        return "Started at \(startTimeFormatted)"
    }

    /// Number of active sharers
    var activeSharersCount: Int {
        participants?.filter { $0.isSharingLocation }.count ?? 0
    }

    /// Participant count formatted
    var participantCountFormatted: String {
        if let count = participantCount {
            return "\(count) participant\(count == 1 ? "" : "s")"
        }
        return "No participants"
    }

    // MARK: - Helper Methods

    /// Check if session should be auto-ended (12 hours inactive)
    func shouldAutoEnd() -> Bool {
        guard isActive else { return false }
        let maxDuration: TimeInterval = 12 * 3600 // 12 hours
        return duration >= maxDuration
    }

    /// Check if user started this session
    func isStarter(_ userId: UUID) -> Bool {
        startedBy == userId
    }

    /// Check if user is participating
    func isParticipating(_ userId: UUID) -> Bool {
        participants?.contains(where: { $0.userId == userId && $0.isCurrentlyInSession }) ?? false
    }

    /// Get participant for user
    func getParticipant(_ userId: UUID) -> SessionParticipant? {
        participants?.first(where: { $0.userId == userId })
    }
}

// MARK: - Session Participant Model
struct SessionParticipant: Codable, Identifiable, Hashable {
    let id: UUID
    let sessionId: UUID
    let userId: UUID
    let joinedAt: Date
    let leftAt: Date?
    let isSharingLocation: Bool
    let lastLocationUpdate: Date?

    // Optional: Populated when joining with users table
    var user: User?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case leftAt = "left_at"
        case isSharingLocation = "is_sharing_location"
        case lastLocationUpdate = "last_location_update"
        case user
    }

    // MARK: - Computed Properties

    /// Check if participant is currently in session
    var isCurrentlyInSession: Bool {
        leftAt == nil
    }

    /// Time since last location update
    var timeSinceLastUpdate: TimeInterval? {
        guard let lastUpdate = lastLocationUpdate else { return nil }
        return Date().timeIntervalSince(lastUpdate)
    }

    /// Is location data fresh (< 2 minutes old)
    var isLocationFresh: Bool {
        guard let timeSince = timeSinceLastUpdate else { return false }
        return timeSince < 120 // 2 minutes
    }

    /// Last seen formatted (e.g., "2 min ago")
    var lastSeenFormatted: String {
        guard let lastUpdate = lastLocationUpdate else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }

    /// Participant session duration
    var sessionDuration: TimeInterval {
        if let left = leftAt {
            return left.timeIntervalSince(joinedAt)
        }
        return Date().timeIntervalSince(joinedAt)
    }

    /// Formatted session duration
    var sessionDurationFormatted: String {
        let hours = Int(sessionDuration) / 3600
        let minutes = (Int(sessionDuration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Display name
    var displayName: String {
        user?.username ?? "Unknown User"
    }

    /// Online status badge color
    var statusColor: String {
        if !isCurrentlyInSession { return "gray" }
        if !isSharingLocation { return "yellow" }
        if isLocationFresh { return "green" }
        return "orange"
    }

    /// Status text
    var statusText: String {
        if !isCurrentlyInSession { return "Left session" }
        if !isSharingLocation { return "Not sharing" }
        if isLocationFresh { return "Online" }
        return "Last seen \(lastSeenFormatted)"
    }

}

// MARK: - Participant Location Model (Real-time)
struct ParticipantLocation: Identifiable, Hashable {
    let id: UUID // userId
    let username: String
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speedMs: Double?
    let batteryLevel: Int?
    let lastUpdate: Date
    let isOnline: Bool

    // MARK: - Computed Properties

    /// Location coordinate
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Location as CLLocation
    var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: lastUpdate
        )
    }

    /// Speed in km/h
    var speedKmh: Double? {
        speedMs.map { $0 * 3.6 }
    }

    /// Speed in mph
    var speedMph: Double? {
        speedMs.map { $0 * 2.237 }
    }

    /// Formatted speed
    var speedFormatted: String {
        guard let speed = speedKmh else { return "—" }
        return String(format: "%.1f km/h", speed)
    }

    /// Short speed format
    var speedShort: String {
        guard let speed = speedKmh else { return "—" }
        return String(format: "%.0f", speed)
    }

    /// Battery level formatted
    var batteryFormatted: String {
        guard let battery = batteryLevel else { return "—" }
        return "\(battery)%"
    }

    /// Battery icon based on level
    var batteryIcon: String {
        guard let battery = batteryLevel else { return "battery.100" }
        if battery >= 75 { return "battery.100" }
        if battery >= 50 { return "battery.75" }
        if battery >= 25 { return "battery.25" }
        return "battery.0"
    }

    /// Is moving (speed > 1 m/s)
    var isMoving: Bool {
        guard let speed = speedMs else { return false }
        return speed > 1.0
    }

    /// Is fast (speed > 10 m/s ~ 36 km/h)
    var isFast: Bool {
        guard let speed = speedMs else { return false }
        return speed > 10.0
    }

    /// Activity status
    var activityStatus: String {
        if !isOnline { return "Offline" }
        if isFast { return "Riding fast" }
        if isMoving { return "Moving" }
        return "Stationary"
    }

    /// Pin color based on activity
    var pinColor: String {
        if !isOnline { return "gray" }
        if isFast { return "red" }
        if isMoving { return "green" }
        return "yellow"
    }

    /// Altitude formatted
    var altitudeFormatted: String {
        guard let alt = altitude else { return "—" }
        return String(format: "%.0f m", alt)
    }

    /// Last update formatted
    var lastUpdateFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }

    // MARK: - Helper Methods

    /// Calculate distance to another location
    func distance(to other: ParticipantLocation) -> CLLocationDistance {
        location.distance(from: other.location)
    }

    /// Formatted distance to another location
    func distanceFormatted(to other: ParticipantLocation) -> String {
        let dist = distance(to: other)
        if dist < 1000 {
            return String(format: "%.0f m away", dist)
        } else {
            return String(format: "%.1f km away", dist / 1000)
        }
    }
}

// MARK: - Sample Data (for previews/testing)
extension GroupSession {
    static let activeSample = GroupSession(
        id: UUID(),
        groupId: UUID(),
        resortId: UUID(),
        startedBy: UUID(),
        startedAt: Date().addingTimeInterval(-7200), // 2 hours ago
        endedAt: nil,
        status: .active,
        resort: Resort.sample,
        participantCount: 5
    )

    static let endedSample = GroupSession(
        id: UUID(),
        groupId: UUID(),
        resortId: UUID(),
        startedBy: UUID(),
        startedAt: Date().addingTimeInterval(-28800), // 8 hours ago
        endedAt: Date().addingTimeInterval(-3600), // ended 1 hour ago
        status: .ended,
        resort: Resort.sampleJapan,
        participantCount: 8
    )
}

extension SessionParticipant {
    static let activeSample = SessionParticipant(
        id: UUID(),
        sessionId: UUID(),
        userId: UUID(),
        joinedAt: Date().addingTimeInterval(-3600), // 1 hour ago
        leftAt: nil,
        isSharingLocation: true,
        lastLocationUpdate: Date().addingTimeInterval(-60), // 1 min ago
        user: User.sample
    )

    static let offlineSample = SessionParticipant(
        id: UUID(),
        sessionId: UUID(),
        userId: UUID(),
        joinedAt: Date().addingTimeInterval(-7200), // 2 hours ago
        leftAt: nil,
        isSharingLocation: false,
        lastLocationUpdate: Date().addingTimeInterval(-1800), // 30 min ago
        user: User.premiumSample
    )

    static let leftSample = SessionParticipant(
        id: UUID(),
        sessionId: UUID(),
        userId: UUID(),
        joinedAt: Date().addingTimeInterval(-5400), // 90 min ago
        leftAt: Date().addingTimeInterval(-1800), // left 30 min ago
        isSharingLocation: false,
        lastLocationUpdate: Date().addingTimeInterval(-1800),
        user: User.sample
    )
}

extension ParticipantLocation {
    static let sample = ParticipantLocation(
        id: UUID(),
        username: "snow_rider_42",
        latitude: 50.1163,
        longitude: -122.9574,
        altitude: 2000,
        speedMs: 12.5,
        batteryLevel: 75,
        lastUpdate: Date(),
        isOnline: true
    )

    static let movingSample = ParticipantLocation(
        id: UUID(),
        username: "pro_skier",
        latitude: 50.1170,
        longitude: -122.9580,
        altitude: 1950,
        speedMs: 5.0,
        batteryLevel: 45,
        lastUpdate: Date(),
        isOnline: true
    )

    static let stationarySample = ParticipantLocation(
        id: UUID(),
        username: "slope_master",
        latitude: 50.1165,
        longitude: -122.9575,
        altitude: 2050,
        speedMs: 0.5,
        batteryLevel: 90,
        lastUpdate: Date(),
        isOnline: true
    )

    static let offlineSample = ParticipantLocation(
        id: UUID(),
        username: "weekend_warrior",
        latitude: 50.1160,
        longitude: -122.9570,
        altitude: 2100,
        speedMs: 0,
        batteryLevel: 20,
        lastUpdate: Date().addingTimeInterval(-600), // 10 min ago
        isOnline: false
    )
}

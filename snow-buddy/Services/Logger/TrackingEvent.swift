//
//  TrackingEvent.swift
//  snow-buddy
//
//  Structured events for tracking system logging
//

import Foundation
import CoreLocation

// MARK: - Tracking Event

enum TrackingEvent {
    // Session events
    case sessionStarted(config: String)
    case sessionStopped(runCount: Int)

    // Run detection events
    case detectionStarted(speed: Double, count: Int, required: Int)
    case detectionReset(speed: Double)
    case detectionThresholdMet(speed: Double, count: Int)

    // Run lifecycle events
    case runStarted(elevation: Double, speed: Double)
    case runUpdated
    case runEnded(duration: TimeInterval, distance: Double, topSpeed: Double, avgSpeed: Double, descent: Double)
    case runValidationFailed(reasons: [String])

    // Location events
    case locationProcessed(speed: Double, elevation: Double, latitude: Double, longitude: Double, distance: Double)
    case locationFiltered(reason: String, accuracy: Double)
    case unrealisticDistance(distance: Double)

    // State transitions
    case stateTransition(from: String, to: String)

    // MARK: - Properties

    var category: String {
        switch self {
        case .sessionStarted, .sessionStopped:
            return "Session"
        case .detectionStarted, .detectionReset, .detectionThresholdMet:
            return "Detection"
        case .runStarted, .runUpdated, .runEnded, .runValidationFailed:
            return "Run"
        case .locationProcessed, .locationFiltered, .unrealisticDistance:
            return "Location"
        case .stateTransition:
            return "State"
        }
    }

    var message: String {
        switch self {
        case .sessionStarted:
            return "Started"
        case .sessionStopped:
            return "Stopped"
        case .detectionStarted:
            return "Building speed"
        case .detectionReset:
            return "Reset - speed dropped"
        case .detectionThresholdMet:
            return "Threshold met"
        case .runStarted:
            return "Started"
        case .runUpdated:
            return "Updated"
        case .runEnded:
            return "Ended"
        case .runValidationFailed:
            return "Validation failed"
        case .locationProcessed:
            return "Processed"
        case .locationFiltered:
            return "Filtered"
        case .unrealisticDistance:
            return "Unrealistic distance detected"
        case .stateTransition:
            return "Transition"
        }
    }

    var level: LogLevel {
        switch self {
        case .sessionStarted, .sessionStopped:
            return .info
        case .detectionStarted, .detectionReset:
            return .debug
        case .detectionThresholdMet, .runStarted, .runEnded:
            return .success
        case .runUpdated:
            return .debug
        case .runValidationFailed:
            return .warning
        case .locationProcessed:
            return .debug
        case .locationFiltered, .unrealisticDistance:
            return .warning
        case .stateTransition:
            return .debug
        }
    }

    var metadata: [String: Any] {
        switch self {
        case .sessionStarted(let config):
            return ["config": config]

        case .sessionStopped(let runCount):
            return ["run_count": runCount]

        case .detectionStarted(let speed, let count, let required):
            return [
                "speed_kmh": speed * 3.6,
                "count": "\(count)/\(required)"
            ]

        case .detectionReset(let speed):
            return ["speed_kmh": speed * 3.6]

        case .detectionThresholdMet(let speed, let count):
            return [
                "speed_kmh": speed * 3.6,
                "readings": count
            ]

        case .runStarted(let elevation, let speed):
            return [
                "elevation_m": elevation,
                "speed_kmh": speed * 3.6
            ]

        case .runUpdated:
            return [:]

        case .runEnded(let duration, let distance, let topSpeed, let avgSpeed, let descent):
            return [
                "duration_s": Int(duration),
                "distance_m": distance,
                "top_speed_kmh": topSpeed * 3.6,
                "avg_speed_kmh": avgSpeed * 3.6,
                "descent_m": descent
            ]

        case .runValidationFailed(let reasons):
            return ["reasons": reasons.joined(separator: "; ")]

        case .locationProcessed(let speed, let elevation, let latitude, let longitude, let distance):
            return [
                "speed_kmh": speed * 3.6,
                "elevation_m": elevation,
                "lat": String(format: "%.4f", latitude),
                "lon": String(format: "%.4f", longitude),
                "distance_m": distance
            ]

        case .locationFiltered(let reason, let accuracy):
            return [
                "reason": reason,
                "accuracy_m": accuracy
            ]

        case .unrealisticDistance(let distance):
            return ["distance_m": distance]

        case .stateTransition(let from, let to):
            return [
                "from": from,
                "to": to
            ]
        }
    }

    // MARK: - Logging Helper

    func log(with logger: Logger?) {
        logger?.log(level, category, message, metadata: metadata)
    }
}

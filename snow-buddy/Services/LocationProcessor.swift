//
//  LocationProcessor.swift
//  snow-buddy
//
//  Handles location validation, filtering, and speed calculation
//

import Foundation
import CoreLocation

// MARK: - Processed Location

struct ProcessedLocation {
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double
    let verticalAccuracy: Double

    var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: timestamp
        )
    }
}

// MARK: - Location Validation Result

enum LocationValidationResult {
    case valid
    case invalid(reason: LocationValidationFailure)
}

enum LocationValidationFailure: String {
    case poorHorizontalAccuracy = "Poor horizontal accuracy"
    case poorVerticalAccuracy = "Poor vertical accuracy"
    case staleTimestamp = "Stale timestamp"
    case negativeAccuracy = "Negative accuracy values"
}

// MARK: - Location Processor

class LocationProcessor {
    // MARK: - Properties

    let config: LocationFilteringConfig
    let speedConfig: SpeedSmoothingConfig
    private let logger: Logger?

    private let kalmanLat: KalmanFilter
    private let kalmanLon: KalmanFilter
    private let kalmanAlt: KalmanFilter

    private var speedHistory: [Double] = []
    private var lastLocation: CLLocation?

    // MARK: - Initialization

    init(
        config: LocationFilteringConfig = .default,
        speedConfig: SpeedSmoothingConfig = .default,
        logger: Logger? = nil
    ) {
        self.config = config
        self.speedConfig = speedConfig
        self.logger = logger

        // Initialize Kalman filters
        self.kalmanLat = KalmanFilter(processNoise: 0.125, measurementNoise: 1.0)
        self.kalmanLon = KalmanFilter(processNoise: 0.125, measurementNoise: 1.0)
        self.kalmanAlt = KalmanFilter(processNoise: 0.125, measurementNoise: 1.0)
    }

    // MARK: - Public Interface

    /// Validate a location reading
    func validate(_ location: CLLocation) -> LocationValidationResult {
        // Check horizontal accuracy
        guard location.horizontalAccuracy >= 0 else {
            let result = LocationValidationResult.invalid(reason: .negativeAccuracy)
            logValidationFailure(result, accuracy: location.horizontalAccuracy)
            return result
        }

        guard location.horizontalAccuracy < config.maxHorizontalAccuracy else {
            let result = LocationValidationResult.invalid(reason: .poorHorizontalAccuracy)
            logValidationFailure(result, accuracy: location.horizontalAccuracy)
            return result
        }

        // Check vertical accuracy
        guard location.verticalAccuracy >= 0 else {
            let result = LocationValidationResult.invalid(reason: .negativeAccuracy)
            logValidationFailure(result, accuracy: location.verticalAccuracy)
            return result
        }

        guard location.verticalAccuracy < config.maxVerticalAccuracy else {
            let result = LocationValidationResult.invalid(reason: .poorVerticalAccuracy)
            logValidationFailure(result, accuracy: location.verticalAccuracy)
            return result
        }

        // Check timestamp freshness
        guard abs(location.timestamp.timeIntervalSinceNow) < config.maxLocationAge else {
            let result = LocationValidationResult.invalid(reason: .staleTimestamp)
            logValidationFailure(result, accuracy: location.horizontalAccuracy)
            return result
        }

        return .valid
    }

    private func logValidationFailure(_ result: LocationValidationResult, accuracy: Double) {
        if case .invalid(let reason) = result {
            TrackingEvent.locationFiltered(reason: reason.rawValue, accuracy: accuracy).log(with: logger)
        }
    }

    /// Process a raw location through Kalman filters
    func process(_ location: CLLocation) -> ProcessedLocation? {
        // Validate first
        guard case .valid = validate(location) else {
            return nil
        }

        // Apply Kalman filtering
        let filteredLat = kalmanLat.filter(location.coordinate.latitude)
        let filteredLon = kalmanLon.filter(location.coordinate.longitude)
        let filteredAlt = kalmanAlt.filter(location.altitude)

        return ProcessedLocation(
            coordinate: CLLocationCoordinate2D(latitude: filteredLat, longitude: filteredLon),
            altitude: filteredAlt,
            timestamp: location.timestamp,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy
        )
    }

    /// Calculate speed from two locations with smoothing
    func calculateSpeed(from: ProcessedLocation, to: ProcessedLocation) -> Double {
        let distance = distance3D(
            from: from.clLocation,
            to: to.clLocation
        )

        let dt = to.timestamp.timeIntervalSince(from.timestamp)

        guard dt >= speedConfig.minTimeDelta else {
            // Time delta too small, return last known speed or 0
            return speedHistory.last ?? 0.0
        }

        let instantSpeed = max(0, distance / dt)

        // Add to smoothing window
        speedHistory.append(instantSpeed)
        if speedHistory.count > speedConfig.windowSize {
            speedHistory.removeFirst()
        }

        // Return moving average
        return speedHistory.reduce(0, +) / Double(speedHistory.count)
    }

    /// Calculate 3D distance between two locations
    func distance3D(from start: CLLocation, to end: CLLocation) -> CLLocationDistance {
        // Horizontal distance (Haversine formula via CLLocation)
        let horizontal = start.distance(from: end)

        // Vertical difference
        let vertical = abs(end.altitude - start.altitude)

        // 3D distance using Pythagorean theorem
        return sqrt(pow(horizontal, 2) + pow(vertical, 2))
    }

    /// Check if distance change is realistic (not a GPS jump)
    func isDistanceRealistic(_ distance: CLLocationDistance) -> Bool {
        if distance < config.minDistanceChange {
            return false  // Too small, likely noise
        }

        if distance >= config.maxDistanceJump {
            return false  // Too large, likely GPS jump
        }

        return true
    }

    /// Reset all filters and state
    func reset() {
        kalmanLat.reset()
        kalmanLon.reset()
        kalmanAlt.reset()
        speedHistory.removeAll()
        lastLocation = nil
    }

    /// Reset speed history (e.g., when starting a new run)
    func resetSpeedHistory() {
        speedHistory.removeAll()
    }

    // MARK: - Location Manager Configuration Helper

    func configureLocationManager(_ manager: LocationManagerProtocol) {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .other
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.distanceFilter = config.distanceFilter
    }
}

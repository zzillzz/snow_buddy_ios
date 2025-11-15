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

    // Enhanced components
    private let adaptiveAccuracyManager: AdaptiveAccuracyManager?
    private let hybridSpeedCalculator: HybridSpeedCalculator?
    private let gpsQualityMonitor: GPSQualityMonitor?

    // Kalman filters (adaptive if available, standard otherwise)
    private let kalmanLat: KalmanFilter
    private let kalmanLon: KalmanFilter
    private let kalmanAlt: KalmanFilter

    private var speedHistory: [Double] = []
    private var lastLocation: CLLocation?
    private var lastSpeedSource: SpeedSource?

    // MARK: - Initialization

    init(
        config: LocationFilteringConfig = .default,
        speedConfig: SpeedSmoothingConfig = .default,
        adaptiveAccuracyConfig: AdaptiveAccuracyConfig? = nil,
        hybridSpeedConfig: HybridSpeedConfig? = nil,
        gpsQualityConfig: GPSQualityConfig? = nil,
        adaptiveKalmanConfig: AdaptiveKalmanConfig? = nil,
        logger: Logger? = nil
    ) {
        self.config = config
        self.speedConfig = speedConfig
        self.logger = logger

        // Initialize enhanced components if configs provided
        if let accuracyConfig = adaptiveAccuracyConfig {
            self.adaptiveAccuracyManager = AdaptiveAccuracyManager(config: accuracyConfig, logger: logger)
        } else {
            self.adaptiveAccuracyManager = nil
        }

        if let speedConfig = hybridSpeedConfig {
            self.hybridSpeedCalculator = HybridSpeedCalculator(config: speedConfig, logger: logger)
        } else {
            self.hybridSpeedCalculator = nil
        }

        if let qualityConfig = gpsQualityConfig {
            self.gpsQualityMonitor = GPSQualityMonitor(config: qualityConfig, logger: logger)
        } else {
            self.gpsQualityMonitor = nil
        }

        // Initialize Kalman filters (adaptive if config provided)
        if let kalmanConfig = adaptiveKalmanConfig {
            self.kalmanLat = AdaptiveKalmanFilter(config: kalmanConfig, logger: logger)
            self.kalmanLon = AdaptiveKalmanFilter(config: kalmanConfig, logger: logger)
            self.kalmanAlt = AdaptiveKalmanFilter(config: kalmanConfig, logger: logger)
        } else {
            self.kalmanLat = KalmanFilter(processNoise: 0.125, measurementNoise: 1.0)
            self.kalmanLon = KalmanFilter(processNoise: 0.125, measurementNoise: 1.0)
            self.kalmanAlt = KalmanFilter(processNoise: 0.125, measurementNoise: 1.0)
        }
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
    func process(_ location: CLLocation, currentSpeed: Double = 0) -> ProcessedLocation? {
        // Validate first
        guard case .valid = validate(location) else {
            return nil
        }

        // Update GPS quality monitor
        gpsQualityMonitor?.updateQuality(from: location)

        // Apply Kalman filtering (adaptive if available)
        let filteredLat: Double
        let filteredLon: Double
        let filteredAlt: Double

        if let adaptiveLat = kalmanLat as? AdaptiveKalmanFilter,
           let adaptiveLon = kalmanLon as? AdaptiveKalmanFilter,
           let adaptiveAlt = kalmanAlt as? AdaptiveKalmanFilter {
            // Use adaptive filtering
            filteredLat = adaptiveLat.filterAdaptive(
                location.coordinate.latitude,
                accuracy: location.horizontalAccuracy,
                speed: currentSpeed
            )
            filteredLon = adaptiveLon.filterAdaptive(
                location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                speed: currentSpeed
            )
            filteredAlt = adaptiveAlt.filterAdaptive(
                location.altitude,
                accuracy: location.verticalAccuracy,
                speed: currentSpeed
            )
        } else {
            // Use standard filtering
            filteredLat = kalmanLat.filter(location.coordinate.latitude)
            filteredLon = kalmanLon.filter(location.coordinate.longitude)
            filteredAlt = kalmanAlt.filter(location.altitude)
        }

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
        let dt = to.timestamp.timeIntervalSince(from.timestamp)

        guard dt >= speedConfig.minTimeDelta else {
            // Time delta too small, return last known speed or 0
            return speedHistory.last ?? 0.0
        }

        let instantSpeed: Double

        // Use hybrid speed calculator if available
        if let hybridCalculator = hybridSpeedCalculator {
            let (speed, source) = hybridCalculator.calculateSpeed(
                currentLocation: to.clLocation,
                previousLocation: from.clLocation
            )
            instantSpeed = speed
            lastSpeedSource = source
        } else {
            // Fallback to calculated speed
            let distance = distance3D(from: from.clLocation, to: to.clLocation)
            instantSpeed = max(0, distance / dt)
            lastSpeedSource = .calculated
        }

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
        gpsQualityMonitor?.reset()
        hybridSpeedCalculator?.resetStatistics()
    }

    /// Reset speed history (e.g., when starting a new run)
    func resetSpeedHistory() {
        speedHistory.removeAll()
    }

    // MARK: - Enhanced Features Access

    /// Get current GPS quality
    func getCurrentGPSQuality() -> GPSQuality? {
        return gpsQualityMonitor?.getQuality()
    }

    /// Check if user should be warned about poor GPS
    func shouldWarnAboutGPSQuality() -> Bool {
        return gpsQualityMonitor?.shouldWarnUser() ?? false
    }

    /// Get GPS quality description for UI
    func getGPSQualityDescription() -> String? {
        return gpsQualityMonitor?.qualityDescription()
    }

    /// Get last speed source (GPS vs calculated)
    func getLastSpeedSource() -> SpeedSource? {
        return lastSpeedSource
    }

    /// Update GPS accuracy based on conditions
    func updateAccuracyIfNeeded(
        manager: LocationManagerProtocol,
        currentSpeed: Double,
        batteryLevel: Float? = nil,
        isPluggedIn: Bool? = nil
    ) {
        guard let accuracyManager = adaptiveAccuracyManager else { return }

        let newAccuracy = accuracyManager.determineAccuracy(
            speed: currentSpeed,
            batteryLevel: batteryLevel,
            isPluggedIn: isPluggedIn
        )

        if accuracyManager.shouldUpdateAccuracy(newAccuracy: newAccuracy) {
            manager.desiredAccuracy = newAccuracy
            accuracyManager.updateCurrentAccuracy(newAccuracy)
        }
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

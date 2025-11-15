//
//  HybridSpeedCalculator.swift
//  snow-buddy
//
//  Intelligently chooses between GPS speed and calculated speed
//

import Foundation
import CoreLocation

enum SpeedSource {
    case gps
    case calculated
    case hybrid
}

class HybridSpeedCalculator {
    // MARK: - Properties

    let config: HybridSpeedConfig
    private let logger: Logger?

    private var lastSpeedSource: SpeedSource?
    private var gpsSpeedUsageCount: Int = 0
    private var calculatedSpeedUsageCount: Int = 0

    // MARK: - Initialization

    init(config: HybridSpeedConfig = .default, logger: Logger? = nil) {
        self.config = config
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Calculate speed using hybrid approach
    func calculateSpeed(
        currentLocation: CLLocation,
        previousLocation: CLLocation
    ) -> (speed: Double, source: SpeedSource) {
        // If hybrid is disabled, always use calculated
        guard config.enabled else {
            let calculatedSpeed = calculateSpeedFromDistance(from: previousLocation, to: currentLocation)
            calculatedSpeedUsageCount += 1
            return (calculatedSpeed, .calculated)
        }

        // Get both speeds
        let gpsSpeed = currentLocation.speed
        let calculatedSpeed = calculateSpeedFromDistance(from: previousLocation, to: currentLocation)

        // Decide which to use
        let shouldUseGPS = shouldUseGPSSpeed(
            gpsSpeed: gpsSpeed,
            calculatedSpeed: calculatedSpeed,
            location: currentLocation
        )

        let finalSpeed: Double
        let source: SpeedSource

        if shouldUseGPS {
            finalSpeed = max(0, gpsSpeed)
            source = .gps
            gpsSpeedUsageCount += 1

            if lastSpeedSource == .calculated {
                logger?.debug("Speed", "Switched to GPS speed", metadata: [
                    "gps_speed_kmh": gpsSpeed * 3.6,
                    "calculated_speed_kmh": calculatedSpeed * 3.6,
                    "accuracy_m": currentLocation.horizontalAccuracy
                ])
            }
        } else {
            finalSpeed = calculatedSpeed
            source = .calculated
            calculatedSpeedUsageCount += 1

            if lastSpeedSource == .gps {
                logger?.debug("Speed", "Switched to calculated speed", metadata: [
                    "gps_speed_kmh": gpsSpeed * 3.6,
                    "calculated_speed_kmh": calculatedSpeed * 3.6,
                    "accuracy_m": currentLocation.horizontalAccuracy
                ])
            }
        }

        lastSpeedSource = source
        return (finalSpeed, source)
    }

    /// Check if GPS speed should be used
    func shouldUseGPSSpeed(
        gpsSpeed: Double,
        calculatedSpeed: Double,
        location: CLLocation
    ) -> Bool {
        // GPS speed must be valid
        guard gpsSpeed >= 0 else {
            return false
        }

        // Must have good horizontal accuracy
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < config.gpsSpeedMaxAccuracy else {
            return false
        }

        // At high speeds, strongly prefer GPS speed
        if calculatedSpeed > config.trustGPSSpeedAbove {
            return true
        }

        // Must be above minimum speed threshold
        if calculatedSpeed >= config.gpsSpeedMinimumSpeed {
            // Use GPS if speeds are reasonably close (within 30%)
            let difference = abs(gpsSpeed - calculatedSpeed)
            let average = (gpsSpeed + calculatedSpeed) / 2.0
            let percentDifference = average > 0 ? (difference / average) : 0

            return percentDifference < 0.3
        }

        return false
    }

    // MARK: - Private Methods

    private func calculateSpeedFromDistance(from: CLLocation, to: CLLocation) -> Double {
        let distance = from.distance(from: to)
        let dt = to.timestamp.timeIntervalSince(from.timestamp)

        guard dt > 0 else { return 0 }

        return max(0, distance / dt)
    }

    // MARK: - Statistics

    func getUsageStatistics() -> (gpsCount: Int, calculatedCount: Int, gpsPercentage: Double) {
        let total = gpsSpeedUsageCount + calculatedSpeedUsageCount
        let percentage = total > 0 ? Double(gpsSpeedUsageCount) / Double(total) * 100.0 : 0.0
        return (gpsSpeedUsageCount, calculatedSpeedUsageCount, percentage)
    }

    func resetStatistics() {
        gpsSpeedUsageCount = 0
        calculatedSpeedUsageCount = 0
        lastSpeedSource = nil
    }
}

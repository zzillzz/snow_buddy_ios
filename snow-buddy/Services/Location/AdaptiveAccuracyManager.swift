//
//  AdaptiveAccuracyManager.swift
//  snow-buddy
//
//  Dynamically adjusts GPS accuracy based on movement and battery conditions
//

import Foundation
import CoreLocation
import UIKit

class AdaptiveAccuracyManager {
    // MARK: - Properties

    let config: AdaptiveAccuracyConfig
    private let logger: Logger?

    private var currentAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    private var lastAccuracyUpdate: Date?
    private let minimumUpdateInterval: TimeInterval = 10.0  // Don't update more than every 10 seconds

    // MARK: - Initialization

    init(config: AdaptiveAccuracyConfig = .default, logger: Logger? = nil) {
        self.config = config
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Determine the optimal accuracy based on current conditions
    func determineAccuracy(
        speed: Double,
        batteryLevel: Float? = nil,
        isPluggedIn: Bool? = nil
    ) -> CLLocationAccuracy {
        // Start with accuracy based on speed
        var accuracy = accuracyForSpeed(speed)

        // Apply battery optimization if needed
        if config.reducesAccuracyOnLowBattery {
            accuracy = applyBatteryOptimization(
                accuracy: accuracy,
                batteryLevel: batteryLevel ?? currentBatteryLevel(),
                isPluggedIn: isPluggedIn ?? isDevicePluggedIn()
            )
        }

        return accuracy
    }

    /// Check if accuracy should be updated (to avoid too frequent changes)
    func shouldUpdateAccuracy(
        newAccuracy: CLLocationAccuracy,
        force: Bool = false
    ) -> Bool {
        // If forced, always update
        if force {
            return true
        }

        // Don't update if same accuracy
        if newAccuracy == currentAccuracy {
            return false
        }

        // Don't update too frequently
        if let lastUpdate = lastAccuracyUpdate {
            let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceUpdate < minimumUpdateInterval {
                return false
            }
        }

        return true
    }

    /// Update the tracked current accuracy
    func updateCurrentAccuracy(_ accuracy: CLLocationAccuracy) {
        let previousAccuracy = currentAccuracy
        currentAccuracy = accuracy
        lastAccuracyUpdate = Date()

        if previousAccuracy != accuracy {
            logger?.info("Accuracy", "Accuracy changed", metadata: [
                "from": accuracyDescription(previousAccuracy),
                "to": accuracyDescription(accuracy)
            ])
        }
    }

    // MARK: - Private Methods

    private func accuracyForSpeed(_ speed: Double) -> CLLocationAccuracy {
        if speed < config.stationaryThreshold {
            return config.stationaryAccuracy
        } else if speed < config.walkingThreshold {
            return config.walkingAccuracy
        } else if speed < config.movingThreshold {
            return config.movingAccuracy
        } else {
            return config.fastAccuracy
        }
    }

    private func applyBatteryOptimization(
        accuracy: CLLocationAccuracy,
        batteryLevel: Float,
        isPluggedIn: Bool
    ) -> CLLocationAccuracy {
        // If plugged in, don't reduce accuracy
        if isPluggedIn {
            return accuracy
        }

        // If battery is above threshold, don't reduce accuracy
        if batteryLevel > config.batteryThreshold {
            return accuracy
        }

        // Reduce accuracy by one level
        let reducedAccuracy = reduceAccuracy(accuracy)

        logger?.warning("Accuracy", "Reducing accuracy due to low battery", metadata: [
            "battery_level": Int(batteryLevel * 100),
            "original": accuracyDescription(accuracy),
            "reduced": accuracyDescription(reducedAccuracy)
        ])

        return reducedAccuracy
    }

    private func reduceAccuracy(_ accuracy: CLLocationAccuracy) -> CLLocationAccuracy {
        switch accuracy {
        case kCLLocationAccuracyBestForNavigation:
            return kCLLocationAccuracyBest
        case kCLLocationAccuracyBest:
            return kCLLocationAccuracyNearestTenMeters
        case kCLLocationAccuracyNearestTenMeters:
            return kCLLocationAccuracyHundredMeters
        case kCLLocationAccuracyHundredMeters:
            return kCLLocationAccuracyKilometer
        default:
            return accuracy
        }
    }

    private func currentBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    private func isDevicePluggedIn() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let state = UIDevice.current.batteryState
        return state == .charging || state == .full
    }

    private func accuracyDescription(_ accuracy: CLLocationAccuracy) -> String {
        switch accuracy {
        case kCLLocationAccuracyBestForNavigation:
            return "BestForNavigation"
        case kCLLocationAccuracyBest:
            return "Best"
        case kCLLocationAccuracyNearestTenMeters:
            return "NearestTenMeters"
        case kCLLocationAccuracyHundredMeters:
            return "HundredMeters"
        case kCLLocationAccuracyKilometer:
            return "Kilometer"
        case kCLLocationAccuracyThreeKilometers:
            return "ThreeKilometers"
        default:
            return "\(Int(accuracy))m"
        }
    }

    // MARK: - Helper Methods

    func getCurrentAccuracy() -> CLLocationAccuracy {
        return currentAccuracy
    }

    func getSpeedCategory(for speed: Double) -> String {
        if speed < config.stationaryThreshold {
            return "Stationary"
        } else if speed < config.walkingThreshold {
            return "Walking"
        } else if speed < config.movingThreshold {
            return "Moving"
        } else {
            return "Fast"
        }
    }
}

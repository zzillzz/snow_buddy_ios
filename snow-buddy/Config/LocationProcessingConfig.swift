//
//  LocationProcessingConfig.swift
//  snow-buddy
//
//  Configuration for advanced location processing features
//

import Foundation
import CoreLocation

// MARK: - Adaptive Accuracy Configuration

struct AdaptiveAccuracyConfig {
    /// Accuracy when stationary (< 1 m/s)
    var stationaryAccuracy: CLLocationAccuracy

    /// Accuracy when walking (1-3 m/s)
    var walkingAccuracy: CLLocationAccuracy

    /// Accuracy when moving (3-10 m/s)
    var movingAccuracy: CLLocationAccuracy

    /// Accuracy when fast (> 10 m/s)
    var fastAccuracy: CLLocationAccuracy

    /// Speed threshold for stationary (m/s)
    var stationaryThreshold: Double

    /// Speed threshold for walking (m/s)
    var walkingThreshold: Double

    /// Speed threshold for moving (m/s)
    var movingThreshold: Double

    /// Battery level below which to reduce accuracy (0.0-1.0)
    var batteryThreshold: Float

    /// Whether to reduce accuracy on low battery
    var reducesAccuracyOnLowBattery: Bool

    static let `default` = AdaptiveAccuracyConfig(
        stationaryAccuracy: kCLLocationAccuracyHundredMeters,
        walkingAccuracy: kCLLocationAccuracyNearestTenMeters,
        movingAccuracy: kCLLocationAccuracyBest,
        fastAccuracy: kCLLocationAccuracyBestForNavigation,
        stationaryThreshold: 1.0,
        walkingThreshold: 3.0,
        movingThreshold: 10.0,
        batteryThreshold: 0.20,
        reducesAccuracyOnLowBattery: true
    )

    /// High accuracy mode - always use best accuracy
    static let highAccuracy = AdaptiveAccuracyConfig(
        stationaryAccuracy: kCLLocationAccuracyBest,
        walkingAccuracy: kCLLocationAccuracyBest,
        movingAccuracy: kCLLocationAccuracyBestForNavigation,
        fastAccuracy: kCLLocationAccuracyBestForNavigation,
        stationaryThreshold: 1.0,
        walkingThreshold: 3.0,
        movingThreshold: 10.0,
        batteryThreshold: 0.10,
        reducesAccuracyOnLowBattery: false
    )

    /// Battery saver mode - always use lower accuracy
    static let batterySaver = AdaptiveAccuracyConfig(
        stationaryAccuracy: kCLLocationAccuracyKilometer,
        walkingAccuracy: kCLLocationAccuracyHundredMeters,
        movingAccuracy: kCLLocationAccuracyNearestTenMeters,
        fastAccuracy: kCLLocationAccuracyBest,
        stationaryThreshold: 1.0,
        walkingThreshold: 3.0,
        movingThreshold: 10.0,
        batteryThreshold: 0.30,
        reducesAccuracyOnLowBattery: true
    )

    /// Racing mode - prioritize accuracy over battery
    static let racing = AdaptiveAccuracyConfig(
        stationaryAccuracy: kCLLocationAccuracyBest,
        walkingAccuracy: kCLLocationAccuracyBest,
        movingAccuracy: kCLLocationAccuracyBestForNavigation,
        fastAccuracy: kCLLocationAccuracyBestForNavigation,
        stationaryThreshold: 1.0,
        walkingThreshold: 3.0,
        movingThreshold: 8.0,
        batteryThreshold: 0.05,
        reducesAccuracyOnLowBattery: false
    )
}

// MARK: - Hybrid Speed Configuration

struct HybridSpeedConfig {
    /// Minimum speed to consider using GPS speed (m/s)
    var gpsSpeedMinimumSpeed: Double

    /// Maximum horizontal accuracy to trust GPS speed (meters)
    var gpsSpeedMaxAccuracy: Double

    /// Speed above which to strongly prefer GPS speed (m/s)
    var trustGPSSpeedAbove: Double

    /// Whether to use hybrid speed calculation
    var enabled: Bool

    static let `default` = HybridSpeedConfig(
        gpsSpeedMinimumSpeed: 5.0,
        gpsSpeedMaxAccuracy: 10.0,
        trustGPSSpeedAbove: 10.0,
        enabled: true
    )

    /// Always prefer calculated speed
    static let calculatedOnly = HybridSpeedConfig(
        gpsSpeedMinimumSpeed: 1000.0,  // Unreachable
        gpsSpeedMaxAccuracy: 1.0,
        trustGPSSpeedAbove: 1000.0,
        enabled: false
    )

    /// Prefer GPS speed when available
    static let gpsPreferred = HybridSpeedConfig(
        gpsSpeedMinimumSpeed: 2.0,
        gpsSpeedMaxAccuracy: 20.0,
        trustGPSSpeedAbove: 5.0,
        enabled: true
    )
}

// MARK: - GPS Quality Configuration

struct GPSQualityConfig {
    /// Accuracy threshold for excellent quality (meters)
    var excellentThreshold: Double

    /// Accuracy threshold for good quality (meters)
    var goodThreshold: Double

    /// Accuracy threshold for fair quality (meters)
    var fairThreshold: Double

    /// Accuracy threshold for poor quality (meters)
    var poorThreshold: Double

    /// Number of samples to average for quality assessment
    var sampleWindow: Int

    /// Whether to warn user about poor quality
    var warnsUser: Bool

    static let `default` = GPSQualityConfig(
        excellentThreshold: 5.0,
        goodThreshold: 15.0,
        fairThreshold: 30.0,
        poorThreshold: 50.0,
        sampleWindow: 10,
        warnsUser: true
    )

    /// Strict quality requirements
    static let strict = GPSQualityConfig(
        excellentThreshold: 3.0,
        goodThreshold: 10.0,
        fairThreshold: 20.0,
        poorThreshold: 35.0,
        sampleWindow: 15,
        warnsUser: true
    )

    /// Lenient quality requirements
    static let lenient = GPSQualityConfig(
        excellentThreshold: 10.0,
        goodThreshold: 25.0,
        fairThreshold: 50.0,
        poorThreshold: 100.0,
        sampleWindow: 5,
        warnsUser: false
    )
}

// MARK: - Adaptive Kalman Configuration

struct AdaptiveKalmanConfig {
    /// Base process noise
    var baseProcessNoise: Double

    /// Base measurement noise
    var baseMeasurementNoise: Double

    /// Noise increase factor per m/s of speed
    var speedNoiseFacto: Double

    /// Noise increase factor for poor accuracy
    var accuracyNoiseFactor: Double

    /// Whether to adapt noise parameters
    var enabled: Bool

    static let `default` = AdaptiveKalmanConfig(
        baseProcessNoise: 0.125,
        baseMeasurementNoise: 1.0,
        speedNoiseFacto: 0.01,
        accuracyNoiseFactor: 0.1,
        enabled: true
    )

    /// Fixed noise (non-adaptive)
    static let fixed = AdaptiveKalmanConfig(
        baseProcessNoise: 0.125,
        baseMeasurementNoise: 1.0,
        speedNoiseFacto: 0.0,
        accuracyNoiseFactor: 0.0,
        enabled: false
    )

    /// More aggressive adaptation
    static let aggressive = AdaptiveKalmanConfig(
        baseProcessNoise: 0.125,
        baseMeasurementNoise: 1.0,
        speedNoiseFacto: 0.02,
        accuracyNoiseFactor: 0.2,
        enabled: true
    )
}

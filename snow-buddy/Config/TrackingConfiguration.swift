//
//  TrackingConfiguration.swift
//  snow-buddy
//
//  Configuration objects for tracking behavior
//

import Foundation
import CoreLocation

// MARK: - Main Configuration

struct TrackingConfiguration {
    var runDetection: RunDetectionConfig
    var validation: RunValidationConfig
    var locationFiltering: LocationFilteringConfig
    var speedSmoothing: SpeedSmoothingConfig
    var logging: LoggingConfig

    // Phase 3: Enhanced location processing
    var adaptiveAccuracy: AdaptiveAccuracyConfig?
    var hybridSpeed: HybridSpeedConfig?
    var gpsQuality: GPSQualityConfig?
    var adaptiveKalman: AdaptiveKalmanConfig?

    static let `default` = TrackingConfiguration(
        runDetection: .default,
        validation: .default,
        locationFiltering: .default,
        speedSmoothing: .default,
        logging: .default,
        adaptiveAccuracy: .default,
        hybridSpeed: .default,
        gpsQuality: .default,
        adaptiveKalman: .default
    )

    /// High accuracy configuration with all enhancements
    static let highAccuracy = TrackingConfiguration(
        runDetection: .default,
        validation: .strict,
        locationFiltering: .highAccuracy,
        speedSmoothing: .responsive,
        logging: .default,
        adaptiveAccuracy: .highAccuracy,
        hybridSpeed: .gpsPreferred,
        gpsQuality: .strict,
        adaptiveKalman: .default
    )

    /// Battery saver configuration
    static let batterySaver = TrackingConfiguration(
        runDetection: .default,
        validation: .default,
        locationFiltering: .batterySaver,
        speedSmoothing: .smooth,
        logging: .production,
        adaptiveAccuracy: .batterySaver,
        hybridSpeed: .calculatedOnly,
        gpsQuality: .lenient,
        adaptiveKalman: .fixed
    )

    /// Car testing configuration - NO descent requirement, works on flat roads
    static let carTesting = TrackingConfiguration(
        runDetection: .carTesting,      // Higher speed threshold (18 km/h)
        validation: .carTesting,         // NO descent requirement
        locationFiltering: .default,
        speedSmoothing: .default,
        logging: .default,              // Full logging for debugging
        adaptiveAccuracy: .default,
        hybridSpeed: .gpsPreferred,     // Prefer GPS speed at car speeds
        gpsQuality: .default,
        adaptiveKalman: .default
    )

    /// Super lenient testing - for debugging in parking lots
    static let superLenient = TrackingConfiguration(
        runDetection: RunDetectionConfig(
            startSpeedThreshold: 2.0,    // ~7 km/h - very slow
            stopSpeedThreshold: 0.5,     // ~2 km/h
            sustainedReadingsRequired: 2, // Only 2 readings needed
            stopTimeThreshold: 30.0
        ),
        validation: RunValidationConfig(
            minDuration: 3.0,            // Only 3 seconds
            minDistance: 30.0,           // Only 30 meters
            minDescent: nil              // No descent
        ),
        locationFiltering: .default,
        speedSmoothing: .default,
        logging: .default,
        adaptiveAccuracy: .default,
        hybridSpeed: .default,
        gpsQuality: .lenient,
        adaptiveKalman: .default
    )
}

// MARK: - Run Detection Configuration

struct RunDetectionConfig {
    /// Speed threshold to start detecting a run (m/s)
    var startSpeedThreshold: Double

    /// Speed threshold below which a run is considered stopped (m/s)
    var stopSpeedThreshold: Double

    /// Number of consecutive speed readings above threshold required to start a run
    var sustainedReadingsRequired: Int

    /// Time threshold for inactivity before ending a run (seconds)
    var stopTimeThreshold: TimeInterval

    static let `default` = RunDetectionConfig(
        startSpeedThreshold: 3.5,     // ~12.6 km/h
        stopSpeedThreshold: 1.5,       // ~5.4 km/h
        sustainedReadingsRequired: 3,
        stopTimeThreshold: 30.0
    )

    /// Configuration for testing in a car (higher speeds, no descent required)
    static let carTesting = RunDetectionConfig(
        startSpeedThreshold: 4.2,      // ~15 km/h
        stopSpeedThreshold: 2.0,       // ~7.2 km/h
        sustainedReadingsRequired: 3,
        stopTimeThreshold: 15.0
    )

    /// Configuration for skiing (typically faster than snowboarding)
    static let skiing = RunDetectionConfig(
        startSpeedThreshold: 4.5,      // ~16.2 km/h
        stopSpeedThreshold: 2.0,       // ~7.2 km/h
        sustainedReadingsRequired: 3,
        stopTimeThreshold: 30.0
    )
}

// MARK: - Validation Configuration

struct RunValidationConfig {
    /// Minimum duration for a valid run (seconds)
    var minDuration: TimeInterval

    /// Minimum distance for a valid run (meters)
    var minDistance: Double

    /// Minimum descent for a valid run (meters) - can be disabled for flat terrain testing
    var minDescent: Double?

    static let `default` = RunValidationConfig(
        minDuration: 10.0,
        minDistance: 50.0,
        minDescent: 20.0
    )

    /// Configuration for car testing (no descent required)
    static let carTesting = RunValidationConfig(
        minDuration: 5.0,
        minDistance: 100.0,
        minDescent: nil  // No descent requirement
    )

    /// Strict configuration for actual slope use
    static let strict = RunValidationConfig(
        minDuration: 15.0,
        minDistance: 100.0,
        minDescent: 30.0
    )
}

// MARK: - Location Filtering Configuration

struct LocationFilteringConfig {
    /// Maximum acceptable horizontal accuracy (meters)
    var maxHorizontalAccuracy: Double

    /// Maximum acceptable vertical accuracy (meters)
    var maxVerticalAccuracy: Double

    /// Maximum age of location data (seconds)
    var maxLocationAge: TimeInterval

    /// Maximum realistic distance jump between readings (meters)
    var maxDistanceJump: Double

    /// Minimum distance change to register (meters) - filters tiny movements
    var minDistanceChange: Double

    /// Location update distance filter (meters)
    var distanceFilter: CLLocationDistance

    static let `default` = LocationFilteringConfig(
        maxHorizontalAccuracy: 50.0,
        maxVerticalAccuracy: 50.0,
        maxLocationAge: 5.0,
        maxDistanceJump: 50.0,
        minDistanceChange: 0.1,
        distanceFilter: 5.0
    )

    /// High accuracy configuration for competitions
    static let highAccuracy = LocationFilteringConfig(
        maxHorizontalAccuracy: 20.0,
        maxVerticalAccuracy: 20.0,
        maxLocationAge: 3.0,
        maxDistanceJump: 30.0,
        minDistanceChange: 0.05,
        distanceFilter: 2.0
    )

    /// Battery saving configuration for casual tracking
    static let batterySaver = LocationFilteringConfig(
        maxHorizontalAccuracy: 100.0,
        maxVerticalAccuracy: 100.0,
        maxLocationAge: 10.0,
        maxDistanceJump: 100.0,
        minDistanceChange: 1.0,
        distanceFilter: 10.0
    )
}

// MARK: - Speed Smoothing Configuration

struct SpeedSmoothingConfig {
    /// Number of readings to use for moving average
    var windowSize: Int

    /// Minimum time delta between readings for speed calculation (seconds)
    var minTimeDelta: TimeInterval

    static let `default` = SpeedSmoothingConfig(
        windowSize: 5,
        minTimeDelta: 0.1
    )

    /// More responsive for racing
    static let responsive = SpeedSmoothingConfig(
        windowSize: 3,
        minTimeDelta: 0.05
    )

    /// Smoother for casual tracking
    static let smooth = SpeedSmoothingConfig(
        windowSize: 10,
        minTimeDelta: 0.2
    )
}

// MARK: - Logging Configuration

struct LoggingConfig {
    /// Enable or disable logging completely
    var isEnabled: Bool

    /// Minimum log level to display
    var minimumLevel: LogLevel

    /// Include metadata in logs
    var includeMetadata: Bool

    /// Include timestamp in logs
    var includeTimestamp: Bool

    static let `default` = LoggingConfig(
        isEnabled: true,
        minimumLevel: .debug,
        includeMetadata: true,
        includeTimestamp: false
    )

    /// Production configuration - only warnings and errors
    static let production = LoggingConfig(
        isEnabled: true,
        minimumLevel: .warning,
        includeMetadata: false,
        includeTimestamp: false
    )

    /// Disabled - no logging
    static let disabled = LoggingConfig(
        isEnabled: false,
        minimumLevel: .error,
        includeMetadata: false,
        includeTimestamp: false
    )

    /// Verbose - everything including timestamps
    static let verbose = LoggingConfig(
        isEnabled: true,
        minimumLevel: .debug,
        includeMetadata: true,
        includeTimestamp: true
    )
}

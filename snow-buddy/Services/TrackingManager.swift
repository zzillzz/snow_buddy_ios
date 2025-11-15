//
//  SpeedTrackingManager.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 26/9/2025.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUICore
import SwiftData

class TrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Dependencies

    private let locationManager: LocationManagerProtocol
    private var runManager: RunManager?

    private var locationProcessor: LocationProcessor
    private var runDetectionEngine: RunDetectionEngine
    private var runSessionManager: RunSessionManager
    private var logger: Logger?

    // MARK: - Configuration

    @Published var config: TrackingConfiguration

    // MARK: - Published Properties

    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var isRecording = false

    @Published var currentRun: Run?
    @Published var completedRuns: [Run] = []

    @Published var currentSpeed: Double = 0
    @Published var currentElevation: Double = 0

    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var averageSpeed: Double = 0
    @Published var topSpeed: Double = 0

    @Published var currentRoutePoints: [RoutePoint] = []
    @Published var currentRouteCoordinates: [CLLocationCoordinate2D] = []

    // Phase 3: GPS Quality
    @Published var gpsQuality: GPSQuality = .good
    @Published var shouldWaitForBetterGPS: Bool = false

    // MARK: - Private State

    private var lastProcessedLocation: ProcessedLocation?
    private var lastAccuracyUpdate: Date?
    
    // MARK: - Initialization

    // Default initializer uses real CLLocationManager and default config
    convenience override init() {
        self.init(
            locationManager: CLLocationManager(),
            config: .carTesting // MARK: CHANGE CONFIG HERE!!!!
        )
    }

    // Dependency injection initializer for testing
    init(
        locationManager: LocationManagerProtocol,
        config: TrackingConfiguration = .default,
        logger: Logger? = nil
    ) {
        self.locationManager = locationManager
        self.config = config

        // Initialize logger from config if not provided
        if let logger = logger {
            self.logger = logger
        } else if config.logging.isEnabled {
            self.logger = ConsoleLogger(
                isEnabled: config.logging.isEnabled,
                minimumLevel: config.logging.minimumLevel,
                includeMetadata: config.logging.includeMetadata,
                includeTimestamp: config.logging.includeTimestamp
            )
        } else {
            self.logger = nil
        }

        // Initialize components with configuration
        self.locationProcessor = LocationProcessor(
            config: config.locationFiltering,
            speedConfig: config.speedSmoothing,
            adaptiveAccuracyConfig: config.adaptiveAccuracy,
            hybridSpeedConfig: config.hybridSpeed,
            gpsQualityConfig: config.gpsQuality,
            adaptiveKalmanConfig: config.adaptiveKalman,
            logger: self.logger
        )
        self.runDetectionEngine = RunDetectionEngine(
            config: config.runDetection,
            logger: self.logger
        )
        self.runSessionManager = RunSessionManager(
            config: config.validation,
            logger: self.logger
        )

        super.init()

        setupLocationManager()
        startLocationTracking()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()

        // Use location processor to configure
        locationProcessor.configureLocationManager(locationManager)
    }

    func setModelContext(_ modelContext: ModelContext) {
        self.runManager = RunManager(modelContext: modelContext)
        if let runManager = runManager {
            runSessionManager.setRunManager(runManager)
        }
    }

    // MARK: - Configuration Management

    /// Update the tracking configuration dynamically
    /// - Parameter newConfig: The new configuration to apply
    /// - Note: This will recreate internal components with the new configuration
    func updateConfiguration(_ newConfig: TrackingConfiguration) {
        // Update config
        self.config = newConfig

        // Update or recreate logger
        if newConfig.logging.isEnabled {
            self.logger = ConsoleLogger(
                isEnabled: newConfig.logging.isEnabled,
                minimumLevel: newConfig.logging.minimumLevel,
                includeMetadata: newConfig.logging.includeMetadata,
                includeTimestamp: newConfig.logging.includeTimestamp
            )
        } else {
            self.logger = nil
        }

        // Recreate components with new configuration
        self.locationProcessor = LocationProcessor(
            config: newConfig.locationFiltering,
            speedConfig: newConfig.speedSmoothing,
            adaptiveAccuracyConfig: newConfig.adaptiveAccuracy,
            hybridSpeedConfig: newConfig.hybridSpeed,
            gpsQualityConfig: newConfig.gpsQuality,
            adaptiveKalmanConfig: newConfig.adaptiveKalman,
            logger: self.logger
        )

        self.runDetectionEngine = RunDetectionEngine(
            config: newConfig.runDetection,
            logger: self.logger
        )

        self.runSessionManager = RunSessionManager(
            config: newConfig.validation,
            logger: self.logger
        )

        // Reattach run manager if it exists
        if let runManager = runManager {
            runSessionManager.setRunManager(runManager)
        }

        // Reconfigure location manager with new settings
        locationProcessor.configureLocationManager(locationManager)

        logger?.debug("System", "Configuration updated", metadata: ["config": "\(getCurrentConfigName())"])
    }

    /// Get a friendly name for the current configuration
    private func getCurrentConfigName() -> String {
        if config.runDetection.startSpeedThreshold == TrackingConfiguration.carTesting.runDetection.startSpeedThreshold &&
           config.validation.minDescent == nil {
            return "Car Testing"
        } else if config.runDetection.startSpeedThreshold == TrackingConfiguration.superLenient.runDetection.startSpeedThreshold {
            return "Super Lenient"
        } else if config.runDetection.startSpeedThreshold == TrackingConfiguration.default.runDetection.startSpeedThreshold &&
                  config.validation.minDescent == 20.0 {
            return "Default"
        } else if config.validation.minDuration == 15.0 {
            return "High Accuracy"
        } else if config.locationFiltering.distanceFilter == 10.0 {
            return "Battery Saver"
        } else {
            return "Custom"
        }
    }

    // New method to start location tracking (called on init)
    private func startLocationTracking() {
        locationManager.startUpdatingLocation()
        logger?.debug("System", "Location tracking started", metadata: nil)
    }
    
    // MARK: - Recording Control

    func startRecording() {
        guard !isRecording else { return }

        isRecording = true

        // Reset all state
        runSessionManager.resetSession()
        runDetectionEngine.reset()
        locationProcessor.reset()

        // Reset published properties
        currentRoutePoints.removeAll()
        currentRouteCoordinates.removeAll()
        completedRuns = []
        totalDistance = 0.0
        currentSpeed = 0.0
        averageSpeed = 0.0
        topSpeed = 0.0

        lastProcessedLocation = nil

        TrackingEvent.sessionStarted(config: getCurrentConfigName()).log(with: logger)
    }

    func stopRecording() {
        guard isRecording else { return }

        // End active run if any
        if runSessionManager.hasActiveRun {
            if let run = runSessionManager.endCurrentRun() {
                completedRuns.append(run)
            }
        }

        isRecording = false

        TrackingEvent.sessionStopped(runCount: completedRuns.count).log(with: logger)
    }
    
    // MARK: - Location Manager Delegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let rawLocation = locations.last else { return }

        // Always update user location
        DispatchQueue.main.async {
            self.userLocation = rawLocation.coordinate
        }

        guard isRecording else { return }

        // Process location through filters
        guard let processedLocation = locationProcessor.process(rawLocation, currentSpeed: currentSpeed) else {
            // Location processor already logged why it was filtered
            return
        }

        // Update current elevation
        currentElevation = processedLocation.altitude

        // Calculate speed if we have a previous location
        if let lastLoc = lastProcessedLocation {
            currentSpeed = locationProcessor.calculateSpeed(from: lastLoc, to: processedLocation)

            // Log location processing
            TrackingEvent.locationProcessed(
                speed: currentSpeed,
                elevation: currentElevation,
                latitude: processedLocation.coordinate.latitude,
                longitude: processedLocation.coordinate.longitude,
                distance: totalDistance
            ).log(with: logger)

            // Update GPS accuracy periodically (every 10 seconds)
            updateGPSAccuracyIfNeeded()
        } else {
            currentSpeed = 0
        }

        // Update GPS quality indicators
        updateGPSQualityIndicators()

        // Process run detection state machine
        let transition = runDetectionEngine.processReading(
            location: processedLocation.clLocation,
            speed: currentSpeed
        )

        handleRunStateTransition(transition, location: processedLocation)

        // Track data if run is active
        if runSessionManager.hasActiveRun, let lastLoc = lastProcessedLocation {
            let distance = locationProcessor.distance3D(from: lastLoc.clLocation, to: processedLocation.clLocation)

            // Validate distance is realistic
            if locationProcessor.isDistanceRealistic(distance) {
                runSessionManager.updateCurrentRun(
                    location: processedLocation,
                    speed: currentSpeed,
                    distance: distance
                )

                // Update session totals
                totalDistance += distance

                // Update published properties from session manager
                updatePublishedProperties()
            } else {
                TrackingEvent.unrealisticDistance(distance: distance).log(with: logger)
            }
        }

        lastProcessedLocation = processedLocation
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger?.error("System", "Location error", metadata: ["error": error.localizedDescription])
    }
    
    // MARK: - State Transition Handling

    private func handleRunStateTransition(_ transition: RunStateTransition, location: ProcessedLocation) {
        switch transition {
        case .noChange:
            break

        case .startedDetecting:
            // RunDetectionEngine logs this
            break

        case .runStarted(let startTime, let startElevation):
            runSessionManager.startNewRun(at: location, startTime: startTime)
            locationProcessor.resetSpeedHistory()
            // RunSessionManager logs this
            break

        case .runUpdated:
            // Run is still active, no special action needed
            break

        case .runEnded:
            if let run = runSessionManager.endCurrentRun() {
                completedRuns.append(run)
                updatePublishedProperties()
            }
            // RunSessionManager logs this
            break

        case .detectionReset:
            // RunDetectionEngine logs this
            break
        }
    }

    private func updatePublishedProperties() {
        // Sync published properties with session manager state
        currentRoutePoints = runSessionManager.currentRoutePoints
        currentRouteCoordinates = runSessionManager.currentRouteCoordinates
        averageSpeed = runSessionManager.currentRunAverageSpeed

        // Update top speed from both current run and completed runs
        let sessionTop = runSessionManager.sessionStats.topSpeed
        let currentTop = runSessionManager.currentRunTopSpeed
        topSpeed = max(sessionTop, currentTop)
    }

    // MARK: - GPS Quality & Accuracy Management

    private func updateGPSAccuracyIfNeeded() {
        // Only update every 10 seconds
        if let lastUpdate = lastAccuracyUpdate {
            if Date().timeIntervalSince(lastUpdate) < 10.0 {
                return
            }
        }

        locationProcessor.updateAccuracyIfNeeded(
            manager: locationManager,
            currentSpeed: currentSpeed
        )

        lastAccuracyUpdate = Date()
    }

    private func updateGPSQualityIndicators() {
        if let quality = locationProcessor.getCurrentGPSQuality() {
            DispatchQueue.main.async {
                self.gpsQuality = quality
                self.shouldWaitForBetterGPS = self.locationProcessor.shouldWarnAboutGPSQuality()
            }
        }
    }
    
    // MARK: - Utility Methods

    /// Calculate 3D distance between two locations (kept for backward compatibility)
    func distance3D(from start: CLLocation, to end: CLLocation) -> CLLocationDistance {
        return locationProcessor.distance3D(from: start, to: end)
    }

    // MARK: - Testing/Debug Methods

    func simulateRun() {
        logger?.debug("Debug", "Starting simulate run", metadata: ["has_run_manager": runManager != nil])

        if runManager == nil {
            logger?.error("Debug", "runManager is nil", metadata: nil)
            return
        }

        completedRuns.append(mockRun4)
        runManager?.saveRun(mockRun4)

        DispatchQueue.main.async {
            self.logger?.debug("Debug", "Simulated run saved", metadata: nil)
        }
    }
}

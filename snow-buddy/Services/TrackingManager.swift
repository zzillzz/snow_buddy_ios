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

    private let locationProcessor: LocationProcessor
    private let runDetectionEngine: RunDetectionEngine
    private let runSessionManager: RunSessionManager
    private let logger: Logger?

    // MARK: - Configuration

    let config: TrackingConfiguration

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

    // MARK: - Private State

    private var lastProcessedLocation: ProcessedLocation?
    
    // MARK: - Initialization

    // Default initializer uses real CLLocationManager and default config
    convenience override init() {
        self.init(
            locationManager: CLLocationManager(),
            config: .default
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

        TrackingEvent.sessionStarted(config: "default").log(with: logger)
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
        guard let processedLocation = locationProcessor.process(rawLocation) else {
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
        } else {
            currentSpeed = 0
        }

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

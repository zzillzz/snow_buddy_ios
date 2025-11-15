//
//  RunSessionManager.swift
//  snow-buddy
//
//  Manages active run and session state
//

import Foundation
import CoreLocation

// MARK: - Active Run

class ActiveRun {
    // MARK: - Properties

    let startTime: Date
    let startElevation: Double

    private(set) var routePoints: [RoutePoint] = []
    private(set) var speeds: [Double] = []
    private(set) var topSpeed: Double = 0.0
    private(set) var topSpeedLocation: CLLocation?
    private(set) var distance: Double = 0.0

    // MARK: - Initialization

    init(startTime: Date, startElevation: Double, initialLocation: ProcessedLocation) {
        self.startTime = startTime
        self.startElevation = startElevation

        // Add first route point
        self.routePoints.append(RoutePoint(
            coordinate: initialLocation.coordinate,
            altitude: initialLocation.altitude,
            timestamp: initialLocation.timestamp
        ))
    }

    // MARK: - Update Methods

    func addLocation(_ location: ProcessedLocation, speed: Double, distance: Double) {
        // Prevent duplicate timestamps - check if last point has same timestamp
        if let lastPoint = routePoints.last,
           lastPoint.timestamp == location.timestamp {
            // Skip this point - duplicate timestamp
            return
        }

        // Add route point
        routePoints.append(RoutePoint(
            coordinate: location.coordinate,
            altitude: location.altitude,
            timestamp: location.timestamp
        ))

        // Track speed
        speeds.append(speed)

        // Update top speed
        if speed > topSpeed {
            topSpeed = speed
            topSpeedLocation = location.clLocation
        }

        // Update distance
        self.distance += distance
    }

    // MARK: - Computed Properties

    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    var averageSpeed: Double {
        speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
    }

    var currentElevation: Double {
        routePoints.last?.altitude ?? startElevation
    }

    var verticalDescent: Double {
        max(0, startElevation - currentElevation)
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        routePoints.map { $0.coordinate }
    }

    // MARK: - Conversion

    func toRun(endTime: Date) -> Run {
        let topSpeedPoint = topSpeedLocation.map { loc in
            RoutePoint(
                coordinate: loc.coordinate,
                altitude: loc.altitude,
                timestamp: loc.timestamp
            )
        }

        return Run(
            startTime: startTime,
            endTime: endTime,
            topSpeed: topSpeed,
            averageSpeed: averageSpeed,
            startElevation: startElevation,
            endElevation: currentElevation,
            verticalDescent: verticalDescent,
            runDistance: distance,
            routePoints: routePoints,
            topSpeedPoint: topSpeedPoint
        )
    }
}

// MARK: - Session Stats

struct SessionStats {
    var totalDistance: Double = 0.0
    var topSpeed: Double = 0.0
    var averageSpeed: Double = 0.0
    var runCount: Int = 0

    mutating func update(with run: Run) {
        totalDistance += run.runDistance
        topSpeed = max(topSpeed, run.topSpeed)
        runCount += 1

        // Recalculate session average speed
        // This is simplified - could be weighted by duration
        averageSpeed = (averageSpeed * Double(runCount - 1) + run.averageSpeed) / Double(runCount)
    }

    mutating func reset() {
        totalDistance = 0.0
        topSpeed = 0.0
        averageSpeed = 0.0
        runCount = 0
    }
}

// MARK: - Run Session Manager

class RunSessionManager {
    // MARK: - Properties

    let config: RunValidationConfig
    private var runManager: RunManager?
    private let logger: Logger?

    private(set) var currentRun: ActiveRun?
    private(set) var completedRuns: [Run] = []
    private(set) var sessionStats = SessionStats()

    // MARK: - Initialization

    init(config: RunValidationConfig = .default, runManager: RunManager? = nil, logger: Logger? = nil) {
        self.config = config
        self.runManager = runManager
        self.logger = logger
    }

    // MARK: - Session Management

    func setRunManager(_ runManager: RunManager) {
        self.runManager = runManager
    }

    func startNewRun(at location: ProcessedLocation, startTime: Date = Date()) {
        guard currentRun == nil else {
            logger?.warning("Run", "Attempted to start new run while one is already active", metadata: nil)
            return
        }

        currentRun = ActiveRun(
            startTime: startTime,
            startElevation: location.altitude,
            initialLocation: location
        )

        TrackingEvent.runStarted(elevation: location.altitude, speed: 0).log(with: logger)
    }

    func updateCurrentRun(location: ProcessedLocation, speed: Double, distance: Double) {
        guard let run = currentRun else {
            logger?.warning("Run", "Attempted to update run but no active run exists", metadata: nil)
            return
        }

        run.addLocation(location, speed: speed, distance: distance)
    }

    func endCurrentRun(endTime: Date = Date()) -> Run? {
        guard let activeRun = currentRun else {
            logger?.warning("Run", "Attempted to end run but no active run exists", metadata: nil)
            return nil
        }

        let run = activeRun.toRun(endTime: endTime)

        // Validate the run
        let validationResult = validate(run: run)

        switch validationResult {
        case .valid:
            // Save the run
            completedRuns.append(run)
            runManager?.saveRun(run)
            sessionStats.update(with: run)

            TrackingEvent.runEnded(
                duration: run.duration,
                distance: run.runDistance,
                topSpeed: run.topSpeed,
                avgSpeed: run.averageSpeed,
                descent: run.verticalDescent
            ).log(with: logger)

            currentRun = nil
            return run

        case .invalid(let reasons):
            TrackingEvent.runValidationFailed(reasons: reasons).log(with: logger)
            currentRun = nil
            return nil
        }
    }

    func cancelCurrentRun() {
        if currentRun != nil {
            logger?.info("Run", "Current run cancelled", metadata: nil)
            currentRun = nil
        }
    }

    func resetSession() {
        currentRun = nil
        completedRuns.removeAll()
        sessionStats.reset()
        logger?.debug("Session", "Session reset", metadata: nil)
    }

    // MARK: - Validation

    enum RunValidationResult {
        case valid
        case invalid(reasons: [String])
    }

    func validate(run: Run) -> RunValidationResult {
        var reasons: [String] = []

        // Check minimum duration
        if run.duration < config.minDuration {
            reasons.append("Duration too short: \(String(format: "%.1f", run.duration))s (min: \(config.minDuration)s)")
        }

        // Check minimum distance
        if run.runDistance < config.minDistance {
            reasons.append("Distance too short: \(String(format: "%.1f", run.runDistance))m (min: \(config.minDistance)m)")
        }

        // Check minimum descent (if configured)
        if let minDescent = config.minDescent {
            if run.verticalDescent < minDescent {
                reasons.append("Descent too small: \(String(format: "%.1f", run.verticalDescent))m (min: \(minDescent)m)")
            }
        }

        return reasons.isEmpty ? .valid : .invalid(reasons: reasons)
    }

    // MARK: - Computed Properties

    var hasActiveRun: Bool {
        currentRun != nil
    }

    var currentRunDuration: TimeInterval {
        currentRun?.duration ?? 0
    }

    var currentRunDistance: Double {
        currentRun?.distance ?? 0
    }

    var currentRunAverageSpeed: Double {
        currentRun?.averageSpeed ?? 0
    }

    var currentRunTopSpeed: Double {
        currentRun?.topSpeed ?? 0
    }

    var currentRoutePoints: [RoutePoint] {
        currentRun?.routePoints ?? []
    }

    var currentRouteCoordinates: [CLLocationCoordinate2D] {
        currentRun?.routeCoordinates ?? []
    }
}

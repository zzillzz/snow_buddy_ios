//
//  RunDetectionEngine.swift
//  snow-buddy
//
//  Handles automatic run detection with explicit state machine
//

import Foundation
import CoreLocation

// MARK: - Run State

enum RunState: Equatable {
    case idle
    case detecting(consecutiveReadings: Int)
    case active(startTime: Date, startElevation: Double, lastMovementTime: Date)
    case stopping(stopInitiatedAt: Date)

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }
}

// MARK: - State Transition

enum RunStateTransition {
    case noChange
    case startedDetecting(consecutiveReadings: Int)
    case runStarted(startTime: Date, startElevation: Double)
    case runUpdated(lastMovementTime: Date)
    case runEnded
    case detectionReset
}

// MARK: - Run Detection Engine

class RunDetectionEngine {
    // MARK: - Properties

    private(set) var state: RunState = .idle
    let config: RunDetectionConfig
    private let logger: Logger?

    // MARK: - Initialization

    init(config: RunDetectionConfig = .default, logger: Logger? = nil) {
        self.config = config
        self.logger = logger
    }

    // MARK: - Public Interface

    /// Process a new location and speed reading, returning any state transition
    func processReading(
        location: CLLocation,
        speed: Double,
        currentTime: Date = Date()
    ) -> RunStateTransition {
        switch state {
        case .idle:
            return handleIdleState(location: location, speed: speed, currentTime: currentTime)

        case .detecting(let count):
            return handleDetectingState(
                location: location,
                speed: speed,
                currentTime: currentTime,
                currentCount: count
            )

        case .active(let startTime, let startElevation, let lastMovementTime):
            return handleActiveState(
                location: location,
                speed: speed,
                currentTime: currentTime,
                startTime: startTime,
                startElevation: startElevation,
                lastMovementTime: lastMovementTime
            )

        case .stopping(let stopInitiatedAt):
            return handleStoppingState(
                location: location,
                speed: speed,
                currentTime: currentTime,
                stopInitiatedAt: stopInitiatedAt
            )
        }
    }

    /// Reset the engine to idle state
    func reset() {
        state = .idle
    }

    // MARK: - State Handlers

    private func handleIdleState(
        location: CLLocation,
        speed: Double,
        currentTime: Date
    ) -> RunStateTransition {
        if speed >= config.startSpeedThreshold {
            state = .detecting(consecutiveReadings: 1)
            return .startedDetecting(consecutiveReadings: 1)
        }
        return .noChange
    }

    private func handleDetectingState(
        location: CLLocation,
        speed: Double,
        currentTime: Date,
        currentCount: Int
    ) -> RunStateTransition {
        // Check if speed is still above threshold
        guard speed >= config.startSpeedThreshold else {
            // Speed dropped, reset detection
            state = .idle
            TrackingEvent.detectionReset(speed: speed).log(with: logger)
            return .detectionReset
        }

        // Increment counter
        let newCount = currentCount + 1

        // Check if we've reached the threshold
        if newCount >= config.sustainedReadingsRequired {
            // Start the run!
            state = .active(
                startTime: currentTime,
                startElevation: location.altitude,
                lastMovementTime: currentTime
            )
            TrackingEvent.detectionThresholdMet(speed: speed, count: newCount).log(with: logger)
            return .runStarted(startTime: currentTime, startElevation: location.altitude)
        } else {
            // Still building up to threshold
            state = .detecting(consecutiveReadings: newCount)
            TrackingEvent.detectionStarted(speed: speed, count: newCount, required: config.sustainedReadingsRequired).log(with: logger)
            return .startedDetecting(consecutiveReadings: newCount)
        }
    }

    private func handleActiveState(
        location: CLLocation,
        speed: Double,
        currentTime: Date,
        startTime: Date,
        startElevation: Double,
        lastMovementTime: Date
    ) -> RunStateTransition {
        // Check if still moving
        if speed > config.stopSpeedThreshold {
            // Still moving, update last movement time
            state = .active(
                startTime: startTime,
                startElevation: startElevation,
                lastMovementTime: currentTime
            )
            return .runUpdated(lastMovementTime: currentTime)
        } else {
            // Stopped moving, check if we've been stopped long enough
            let stoppedDuration = currentTime.timeIntervalSince(lastMovementTime)

            if stoppedDuration >= config.stopTimeThreshold {
                // Been stopped long enough, end the run
                state = .idle
                return .runEnded
            } else {
                // Still within grace period, keep state
                return .noChange
            }
        }
    }

    private func handleStoppingState(
        location: CLLocation,
        speed: Double,
        currentTime: Date,
        stopInitiatedAt: Date
    ) -> RunStateTransition {
        // Check if user started moving again
        if speed > config.stopSpeedThreshold {
            // Resume the run - but we'd need the original start time and elevation
            // This state is for future pause/resume functionality
            // For now, just end the run
            state = .idle
            return .runEnded
        }

        // Check if stop timeout reached
        let stoppedDuration = currentTime.timeIntervalSince(stopInitiatedAt)
        if stoppedDuration >= config.stopTimeThreshold {
            state = .idle
            return .runEnded
        }

        return .noChange
    }

    // MARK: - Helper Methods

    /// Check if a run should start based on current conditions
    func shouldStartRun(speed: Double) -> Bool {
        if case .detecting(let count) = state {
            return speed >= config.startSpeedThreshold && count >= config.sustainedReadingsRequired
        }
        return false
    }

    /// Check if a run should end based on current conditions
    func shouldEndRun(speed: Double, lastMovementTime: Date, currentTime: Date) -> Bool {
        guard case .active = state else { return false }

        if speed <= config.stopSpeedThreshold {
            let stoppedDuration = currentTime.timeIntervalSince(lastMovementTime)
            return stoppedDuration >= config.stopTimeThreshold
        }
        return false
    }

    /// Get debug description of current state
    var stateDescription: String {
        switch state {
        case .idle:
            return "Idle"
        case .detecting(let count):
            return "Detecting (\(count)/\(config.sustainedReadingsRequired))"
        case .active(let startTime, let startElevation, let lastMovementTime):
            let duration = Date().timeIntervalSince(startTime)
            return "Active (duration: \(Int(duration))s, elevation: \(Int(startElevation))m)"
        case .stopping(let stopInitiatedAt):
            let duration = Date().timeIntervalSince(stopInitiatedAt)
            return "Stopping (stopped for: \(Int(duration))s)"
        }
    }
}

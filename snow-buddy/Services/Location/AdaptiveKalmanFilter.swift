//
//  AdaptiveKalmanFilter.swift
//  snow-buddy
//
//  Kalman filter that adapts noise parameters based on conditions
//

import Foundation
import CoreLocation

class AdaptiveKalmanFilter: KalmanFilter {
    // MARK: - Properties

    let config: AdaptiveKalmanConfig
    private let logger: Logger?

    private var baseProcessNoise: Double
    private var baseMeasurementNoise: Double

    // MARK: - Initialization

    init(config: AdaptiveKalmanConfig = .default, logger: Logger? = nil) {
        self.config = config
        self.logger = logger
        self.baseProcessNoise = config.baseProcessNoise
        self.baseMeasurementNoise = config.baseMeasurementNoise

        super.init(
            processNoise: config.baseProcessNoise,
            measurementNoise: config.baseMeasurementNoise
        )
    }

    // MARK: - Adaptive Filtering

    /// Filter with adaptive noise based on conditions
    func filterAdaptive(
        _ measurement: Double,
        accuracy: Double,
        speed: Double
    ) -> Double {
        if !config.enabled {
            // Use base filter without adaptation
            return filter(measurement)
        }

        // Calculate adaptive noise parameters
        let adaptedProcessNoise = calculateProcessNoise(speed: speed, accuracy: accuracy)
        let adaptedMeasurementNoise = calculateMeasurementNoise(accuracy: accuracy)

        // Temporarily update noise parameters
        let originalProcessNoise = q
        let originalMeasurementNoise = r

        q = adaptedProcessNoise
        r = adaptedMeasurementNoise

        // Perform filtering
        let filtered = filter(measurement)

        // Restore original parameters
        q = originalProcessNoise
        r = originalMeasurementNoise

        return filtered
    }

    // MARK: - Noise Calculation

    private func calculateProcessNoise(speed: Double, accuracy: Double) -> Double {
        var noise = baseProcessNoise

        // Increase noise with speed (things change faster at high speed)
        if speed > 0 {
            noise += speed * config.speedNoiseFacto
        }

        // Increase noise with poor accuracy (less certain about changes)
        if accuracy > 10.0 {
            let accuracyFactor = min((accuracy - 10.0) / 40.0, 1.0)  // Cap at 50m accuracy
            noise += accuracyFactor * baseProcessNoise * config.accuracyNoiseFactor
        }

        return noise
    }

    private func calculateMeasurementNoise(accuracy: Double) -> Double {
        var noise = baseMeasurementNoise

        // Increase measurement noise with poor accuracy
        if accuracy > 5.0 {
            let accuracyFactor = (accuracy / 50.0)  // Scale by accuracy
            noise += accuracyFactor * baseMeasurementNoise * config.accuracyNoiseFactor
        }

        return noise
    }

    // MARK: - Override Methods

    override func reset() {
        super.reset()
        q = baseProcessNoise
        r = baseMeasurementNoise
    }
}

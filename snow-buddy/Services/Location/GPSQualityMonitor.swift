//
//  GPSQualityMonitor.swift
//  snow-buddy
//
//  Monitors and reports GPS signal quality
//

import Foundation
import CoreLocation

// MARK: - GPS Quality

enum GPSQuality: String, Comparable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case veryPoor = "Very Poor"

    static func < (lhs: GPSQuality, rhs: GPSQuality) -> Bool {
        return lhs.score < rhs.score
    }

    var score: Int {
        switch self {
        case .excellent: return 5
        case .good: return 4
        case .fair: return 3
        case .poor: return 2
        case .veryPoor: return 1
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "🟢"
        case .good: return "🟡"
        case .fair: return "🟠"
        case .poor: return "🔴"
        case .veryPoor: return "⚫"
        }
    }

    var description: String {
        switch self {
        case .excellent:
            return "GPS signal is excellent"
        case .good:
            return "GPS signal is good"
        case .fair:
            return "GPS signal is fair - tracking may be less accurate"
        case .poor:
            return "GPS signal is poor - move to an open area for better tracking"
        case .veryPoor:
            return "GPS signal is very poor - tracking may be unreliable"
        }
    }
}

// MARK: - GPS Quality Monitor

class GPSQualityMonitor {
    // MARK: - Properties

    let config: GPSQualityConfig
    private let logger: Logger?

    private var recentAccuracies: [Double] = []
    private(set) var currentQuality: GPSQuality = .good
    private var lastQualityUpdate: Date?

    // MARK: - Initialization

    init(config: GPSQualityConfig = .default, logger: Logger? = nil) {
        self.config = config
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Update quality assessment with new location
    func updateQuality(from location: CLLocation) {
        // Add accuracy to history
        recentAccuracies.append(location.horizontalAccuracy)

        // Keep only recent samples
        if recentAccuracies.count > config.sampleWindow {
            recentAccuracies.removeFirst()
        }

        // Calculate average accuracy
        let averageAccuracy = recentAccuracies.reduce(0, +) / Double(recentAccuracies.count)

        // Determine quality
        let newQuality = qualityForAccuracy(averageAccuracy)

        // Update if changed
        if newQuality != currentQuality {
            let previousQuality = currentQuality
            currentQuality = newQuality
            lastQualityUpdate = Date()

            logger?.info("GPS", "GPS quality changed", metadata: [
                "from": previousQuality.rawValue,
                "to": newQuality.rawValue,
                "avg_accuracy_m": averageAccuracy
            ])
        }
    }

    /// Get current quality level
    func getQuality() -> GPSQuality {
        return currentQuality
    }

    /// Check if user should be warned about poor quality
    func shouldWarnUser() -> Bool {
        guard config.warnsUser else { return false }
        return currentQuality.score <= GPSQuality.poor.score
    }

    /// Get user-friendly quality description
    func qualityDescription() -> String {
        return "\(currentQuality.emoji) \(currentQuality.description)"
    }

    /// Get average accuracy over sample window
    func getAverageAccuracy() -> Double? {
        guard !recentAccuracies.isEmpty else { return nil }
        return recentAccuracies.reduce(0, +) / Double(recentAccuracies.count)
    }

    /// Reset quality monitoring
    func reset() {
        recentAccuracies.removeAll()
        currentQuality = .good
        lastQualityUpdate = nil
    }

    // MARK: - Private Methods

    private func qualityForAccuracy(_ accuracy: Double) -> GPSQuality {
        if accuracy < config.excellentThreshold {
            return .excellent
        } else if accuracy < config.goodThreshold {
            return .good
        } else if accuracy < config.fairThreshold {
            return .fair
        } else if accuracy < config.poorThreshold {
            return .poor
        } else {
            return .veryPoor
        }
    }

    // MARK: - Statistics

    func getQualityStatistics() -> (quality: GPSQuality, avgAccuracy: Double?, sampleCount: Int) {
        return (currentQuality, getAverageAccuracy(), recentAccuracies.count)
    }
}

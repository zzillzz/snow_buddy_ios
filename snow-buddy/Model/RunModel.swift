//
//  RunModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 26/9/2025.
//
import Foundation
import SwiftData
import CoreLocation

@Model
final class Run {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date
    var topSpeed: Double // m/s
    var averageSpeed: Double // m/s
    var startElevation: Double
    var endElevation: Double
    var verticalDescent: Double
    
    var routePoints: [RoutePoint] = []
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date, topSpeed: Double, averageSpeed: Double, startElevation: Double, endElevation: Double, verticalDescent: Double, routePoints: [RoutePoint] = []) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.topSpeed = topSpeed
        self.averageSpeed = averageSpeed
        self.startElevation = startElevation
        self.endElevation = endElevation
        self.verticalDescent = verticalDescent
        self.routePoints = routePoints
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var topSpeedKmh: Double {
        topSpeed * 3.6
    }
    
    var averageSpeedKmh: Double {
        averageSpeed * 3.6
    }
    
    var distanceInKm: Double {
        let horizontalDistance = hypot(endElevation - startElevation, averageSpeed * duration)
        return horizontalDistance / 1000.0
    }
    
    var coordinates: [CLLocationCoordinate2D] {
        routePoints.map { $0.coordinate }
    }
}

struct DayStats {
    let runs: [Run]
    
    var totalRuns: Int {
        runs.count
    }
    
    var topSpeedOfDay: Double {
        runs.map { $0.topSpeed }.max() ?? 0
    }
    
    var averageSpeedOfDay: Double {
        let totalSpeed = runs.reduce(0) { $0 + $1.averageSpeed }
        return runs.isEmpty ? 0 : totalSpeed / Double(runs.count)
    }
    
    var totalVerticalDescent: Double {
        runs.reduce(0) { $0 + $1.verticalDescent }
    }
}

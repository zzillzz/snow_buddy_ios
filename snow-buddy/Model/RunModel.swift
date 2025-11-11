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
    var runDistance: CLLocationDistance
    
    var routePoints: [RoutePoint]
    var topSpeedPoint: RoutePoint?
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date, topSpeed: Double, averageSpeed: Double, startElevation: Double, endElevation: Double, verticalDescent: Double, runDistance: Double = 0, routePoints: [RoutePoint], topSpeedPoint: RoutePoint? = nil ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.topSpeed = topSpeed
        self.averageSpeed = averageSpeed
        self.startElevation = startElevation
        self.endElevation = endElevation
        self.verticalDescent = verticalDescent
        self.runDistance = runDistance
        self.routePoints = routePoints
        self.topSpeedPoint = topSpeedPoint
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
    
    var runDistanceKm: Double {
        runDistance * 0.001
    }
    
    var distanceInKm: Double {
        let horizontalDistance = hypot(endElevation - startElevation, averageSpeed * duration)
        return horizontalDistance / 1000.0
    }
    
    var coordinates: [CLLocationCoordinate2D] {
        routePoints.map { $0.coordinate }
    }
    
    var averageSlope: Double {
        guard verticalDescent > 0 else { return 0 }
        return atan(verticalDescent / (runDistanceKm * 1000)) * 180 / .pi
    }
    
    func computeSpeeds() -> [(time: Date, speed: Double)] {
        var results: [(Date, Double)] = []
        
        let validPoints = routePoints.sorted {
            ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
        }
        
        for i in 1..<validPoints.count {
            guard
                let t1 = validPoints[i-1].timestamp,
                let t2 = validPoints[i].timestamp
            else { continue }
            
            let loc1 = CLLocation(latitude: validPoints[i-1].latitude, longitude: validPoints[i-1].longitude)
            let loc2 = CLLocation(latitude: validPoints[i].latitude, longitude: validPoints[i].longitude)
            let distance = loc1.distance(from: loc2) // meters
            let deltaTime = t2.timeIntervalSince(t1)
            guard deltaTime > 0 else { continue }
            
            let speed = distance / deltaTime // m/s
            results.append((t2, speed * 3.6)) // convert to km/h
        }
        
        return results
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


func printRunStats(run: Run) {
    run.routePoints.map({ routePoint in
        print("coordinate: \(routePoint.coordinate)")
        print("latitude, longitude: \(routePoint.latitude), \(routePoint.longitude)")
        print("altitude: \(String(describing: routePoint.altitude))")
        print("timestamp: \(String(describing: routePoint.timestamp))")

    })
    print(run.routePoints)
    print(run.topSpeedPoint ?? "no top Speed Point")
}

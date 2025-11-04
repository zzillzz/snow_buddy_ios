//
//  Mocks.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//
import Foundation
import CoreLocation

var mockRun: Run {
    let startTime = Date()
    let endTime = Date().addingTimeInterval(120) // 2 minute run
    
    // Create mock route for preview
    var mockPoints: [RoutePoint] = []
    let baseLat = -37.8136
    let baseLon = 144.9631
    
    for i in 0..<15 {
        mockPoints.append(RoutePoint(
            latitude: baseLat + Double(i) * 0.0001,
            longitude: baseLon + Double(i) * 0.0001,
            altitude: 2000 - Double(i) * 7,
            timestamp: startTime.addingTimeInterval(Double(i) * 8)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 15.0, // 54 km/h
        averageSpeed: 10.0, // 36 km/h
        startElevation: 2000,
        endElevation: 1900,
        verticalDescent: 100
    )
}

func createMockRoute() -> [RoutePoint] {
    // Create a simple zigzag pattern for testing
    var points: [RoutePoint] = []
    let startLat = -37.8136
    let startLon = 144.9631
    let startAlt = 2000.0
    
    for i in 0..<20 {
        let lat = startLat + Double(i) * 0.0001 * (i % 2 == 0 ? 1 : -0.5)
        let lon = startLon + Double(i) * 0.0001
        let alt = startAlt - Double(i) * 5 // Descending
        
        let point = RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: Date().addingTimeInterval(Double(i) * 6)
        )
        points.append(point)
    }
    
    return points
}



var mockRun2: Run {
    let startTime = Date().addingTimeInterval(-3600) // 1 hour ago
    let endTime = startTime.addingTimeInterval(142) // 2 minutes 22 seconds run
    
    // Realistic ski run route - Falls Creek, Victoria (or similar resort)
    // Simulates a run down a slope with natural curves
    var mockPoints: [RoutePoint] = []
    
    // Starting point at top of run
    let startLat = -36.8599
    let startLon = 147.2799
    let startAlt = 1780.0
    
    // Create a realistic curved descent
    let totalPoints = 45
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        
        // Create natural S-curve path (zigzag down the mountain)
        let lateralOffset = sin(progress * .pi * 4) * 0.0008 // Natural turns
        let forwardProgress = progress * 0.0035 // Move down the slope
        
        let lat = startLat - forwardProgress + lateralOffset * 0.3
        let lon = startLon + forwardProgress + lateralOffset
        
        // Natural elevation descent with some variation
        let baseAltDrop = progress * 245 // Total 245m descent
        let altVariation = sin(progress * .pi * 6) * 8 // Small bumps
        let alt = startAlt - baseAltDrop + altVariation
        
        let point = RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 142)
        )
        mockPoints.append(point)
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 18.5, // 66.6 km/h - realistic top speed for intermediate skier
        averageSpeed: 11.2, // 40.3 km/h - good average
        startElevation: startAlt,
        endElevation: startAlt - 245,
        verticalDescent: 245, // Realistic run descent
        routePoints: mockPoints
    )
}

// Extended mock data for previews with multiple runs
extension TrackingManager {
    static var preview2: TrackingManager {
        let manager = TrackingManager()
        manager.completedRuns = [
            mockRun2,
            mockRun3,
            mockRun4
        ]
        return manager
    }
}


extension TrackingManager {
    static var preview: TrackingManager {
        let manager = TrackingManager()
        manager.completedRuns = [mockRun]
        return manager
    }
}

var mockRun3: Run {
    let startTime = Date().addingTimeInterval(-7200) // 2 hours ago
    let endTime = startTime.addingTimeInterval(98) // 1 min 38 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8589
    let startLon = 147.2809
    let startAlt = 1820.0
    
    let totalPoints = 32
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 3) * 0.0006
        let forwardProgress = progress * 0.0028
        
        let lat = startLat - forwardProgress + lateralOffset * 0.4
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 180) + sin(progress * .pi * 5) * 6
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 98)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 22.3, // 80.3 km/h - faster run
        averageSpeed: 13.8, // 49.7 km/h
        startElevation: startAlt,
        endElevation: startAlt - 180,
        verticalDescent: 180,
        routePoints: mockPoints
    )
}

var mockRun4: Run {
    let startTime = Date().addingTimeInterval(-10800) // 3 hours ago
    let endTime = startTime.addingTimeInterval(205) // 3 min 25 sec - longer, easier run
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8579
    let startLon = 147.2819
    let startAlt = 1750.0
    
    let totalPoints = 55
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 5) * 0.0007
        let forwardProgress = progress * 0.004
        
        let lat = startLat - forwardProgress + lateralOffset * 0.35
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 310) + sin(progress * .pi * 7) * 10
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 205)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 15.8, // 56.9 km/h - easier cruising run
        averageSpeed: 9.5, // 34.2 km/h
        startElevation: startAlt,
        endElevation: startAlt - 310,
        verticalDescent: 310,
        routePoints: mockPoints
    )
}


let listOfMockRuns = [mockRun2, mockRun3, mockRun4]

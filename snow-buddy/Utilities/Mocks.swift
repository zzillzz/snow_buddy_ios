////
////  Mocks.swift
////  snow-buddy
////
////  Created by Zill-e-Rahim on 4/11/2025.
////
//import Foundation
//import CoreLocation
//
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
        verticalDescent: 100,
        routePoints: mockPoints
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

let listOfMockRuns = [mockRun2, mockRun3, mockRun4]




import Foundation

// Today - Run 1 (1 hour ago)
var mockRun1: Run {
    let startTime = Date().addingTimeInterval(-3600)
    let endTime = startTime.addingTimeInterval(300) // 5 min
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8589
    let startLon = 147.2809
    let startAlt = 2000.0
    let totalPoints = 40
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 4) * 0.0005
        let forwardProgress = progress * 0.0035
        
        let lat = startLat - forwardProgress + lateralOffset * 0.3
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 300) + sin(progress * .pi * 6) * 8
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 300)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 15.0,
        averageSpeed: 10.5,
        startElevation: startAlt,
        endElevation: startAlt - 300,
        verticalDescent: 300,
        runDistance: 3100, // ~3.1 km
        routePoints: mockPoints
    )
}

// Today - Run 2 (2 hours ago)
var mockRun2: Run {
    let startTime = Date().addingTimeInterval(-7200)
    let endTime = startTime.addingTimeInterval(295) // 4 min 55 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8610
    let startLon = 147.2825
    let startAlt = 2000.0
    let totalPoints = 38
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 3) * 0.0007
        let forwardProgress = progress * 0.0040
        
        let lat = startLat - forwardProgress + lateralOffset * 0.35
        let lon = startLon + forwardProgress + lateralOffset * 0.8
        let alt = startAlt - (progress * 350) + sin(progress * .pi * 7) * 10
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 295)
        ))
    }
    
    let topSpeedIndex = 22
    let topSpeedProgress = Double(topSpeedIndex) / Double(totalPoints - 1)
    let topSpeedLateralOffset = cos(topSpeedProgress * .pi * 3) * 0.0007
    let topSpeedForwardProgress = topSpeedProgress * 0.0040
    
    let topSpeedPoint = RoutePoint(
        latitude: startLat - topSpeedForwardProgress + topSpeedLateralOffset * 0.35,
        longitude: startLon + topSpeedForwardProgress + topSpeedLateralOffset * 0.8,
        altitude: startAlt - (topSpeedProgress * 350) + sin(topSpeedProgress * .pi * 7) * 10,
        timestamp: startTime.addingTimeInterval(topSpeedProgress * 295)
    )
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 18.5,
        averageSpeed: 12.0,
        startElevation: startAlt,
        endElevation: startAlt - 350,
        verticalDescent: 350,
        runDistance: 3450, // ~3.45 km
        routePoints: mockPoints,
        topSpeedPoint: topSpeedPoint
    )
}

// Today - Run 3 (3 hours ago)
var mockRun3: Run {
    let startTime = Date().addingTimeInterval(-10800)
    let endTime = startTime.addingTimeInterval(285) // 4 min 45 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8595
    let startLon = 147.2815
    let startAlt = 2000.0
    let totalPoints = 42
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 5) * 0.0008
        let forwardProgress = progress * 0.0045
        
        let lat = startLat - forwardProgress + lateralOffset * 0.4
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 400) + sin(progress * .pi * 8) * 12
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 285)
        ))
    }
    
    let topSpeedIndex = 26
    let topSpeedProgress = Double(topSpeedIndex) / Double(totalPoints - 1)
    let topSpeedLateralOffset = sin(topSpeedProgress * .pi * 5) * 0.0008
    let topSpeedForwardProgress = topSpeedProgress * 0.0045
    
    let topSpeedPoint = RoutePoint(
        latitude: startLat - topSpeedForwardProgress + topSpeedLateralOffset * 0.4,
        longitude: startLon + topSpeedForwardProgress + topSpeedLateralOffset,
        altitude: startAlt - (topSpeedProgress * 400) + sin(topSpeedProgress * .pi * 8) * 12,
        timestamp: startTime.addingTimeInterval(topSpeedProgress * 285)
    )
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 20.0,
        averageSpeed: 13.5,
        startElevation: startAlt,
        endElevation: startAlt - 400,
        verticalDescent: 400,
        runDistance: 3700, // ~3.7 km
        routePoints: mockPoints,
        topSpeedPoint: topSpeedPoint
    )
}

// Yesterday - Run 1
var mockRun4: Run {
    let startTime = Date().addingTimeInterval(-86400 - 7200)
    let endTime = startTime.addingTimeInterval(310) // 5 min 10 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8600
    let startLon = 147.2820
    let startAlt = 2100.0
    let totalPoints = 36
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 3.5) * 0.0006
        let forwardProgress = progress * 0.0038
        
        let lat = startLat - forwardProgress + lateralOffset * 0.38
        let lon = startLon + forwardProgress + lateralOffset * 0.9
        let alt = startAlt - (progress * 350) + sin(progress * .pi * 6) * 9
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 310)
        ))
    }
    
    let topSpeedIndex = 21
    let topSpeedProgress = Double(topSpeedIndex) / Double(totalPoints - 1)
    let topSpeedLateralOffset = sin(topSpeedProgress * .pi * 3.5) * 0.0006
    let topSpeedForwardProgress = topSpeedProgress * 0.0038
    
    let topSpeedPoint = RoutePoint(
        latitude: startLat - topSpeedForwardProgress + topSpeedLateralOffset * 0.38,
        longitude: startLon + topSpeedForwardProgress + topSpeedLateralOffset * 0.9,
        altitude: startAlt - (topSpeedProgress * 350) + sin(topSpeedProgress * .pi * 6) * 9,
        timestamp: startTime.addingTimeInterval(topSpeedProgress * 310)
    )
    
    let runDistance = 4000.0 // ~4.0 km
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 17.2,
        averageSpeed: 11.8,
        startElevation: startAlt,
        endElevation: startAlt - 350,
        verticalDescent: 350,
        runDistance: runDistance,
        routePoints: mockPoints,
        topSpeedPoint: topSpeedPoint
    )
}

// Yesterday - Run 2
var mockRun5: Run {
    let startTime = Date().addingTimeInterval(-86400 - 14400)
    let endTime = startTime.addingTimeInterval(290) // 4 min 50 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8615
    let startLon = 147.2830
    let startAlt = 2100.0
    let totalPoints = 40
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 4) * 0.0007
        let forwardProgress = progress * 0.0042
        
        let lat = startLat - forwardProgress + lateralOffset * 0.36
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 400) + sin(progress * .pi * 7) * 11
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 290)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 19.5,
        averageSpeed: 13.0,
        startElevation: startAlt,
        endElevation: startAlt - 400,
        verticalDescent: 400,
        runDistance: 3650, // ~3.65 km
        routePoints: mockPoints
    )
}

// 3 days ago - Run 1
var mockRun6: Run {
    let startTime = Date().addingTimeInterval(-259200 - 10800)
    let endTime = startTime.addingTimeInterval(305) // 5 min 5 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8585
    let startLon = 147.2805
    let startAlt = 1950.0
    let totalPoints = 35
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 4.5) * 0.0005
        let forwardProgress = progress * 0.0033
        
        let lat = startLat - forwardProgress + lateralOffset * 0.32
        let lon = startLon + forwardProgress + lateralOffset * 0.85
        let alt = startAlt - (progress * 300) + sin(progress * .pi * 5) * 7
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 305)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 16.8,
        averageSpeed: 11.2,
        startElevation: startAlt,
        endElevation: startAlt - 300,
        verticalDescent: 300,
        runDistance: 3200, // ~3.2 km
        routePoints: mockPoints
    )
}

// 1 week ago - Run 1
var mockRun7: Run {
    let startTime = Date().addingTimeInterval(-604800 - 3600)
    let endTime = startTime.addingTimeInterval(275) // 4 min 35 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8605
    let startLon = 147.2822
    let startAlt = 2200.0
    let totalPoints = 44
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 5.5) * 0.0009
        let forwardProgress = progress * 0.0048
        
        let lat = startLat - forwardProgress + lateralOffset * 0.42
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 400) + sin(progress * .pi * 9) * 13
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 275)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 21.5,
        averageSpeed: 14.0,
        startElevation: startAlt,
        endElevation: startAlt - 400,
        verticalDescent: 400,
        runDistance: 4100, // ~4.1 km
        routePoints: mockPoints
    )
}

// 1 week ago - Run 2
var mockRun8: Run {
    let startTime = Date().addingTimeInterval(-604800 - 7200)
    let endTime = startTime.addingTimeInterval(298) // 4 min 58 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8598
    let startLon = 147.2818
    let startAlt = 2200.0
    let totalPoints = 38
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 3.8) * 0.0006
        let forwardProgress = progress * 0.0039
        
        let lat = startLat - forwardProgress + lateralOffset * 0.37
        let lon = startLon + forwardProgress + lateralOffset * 0.95
        let alt = startAlt - (progress * 350) + sin(progress * .pi * 7) * 10
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 298)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 19.0,
        averageSpeed: 12.5,
        startElevation: startAlt,
        endElevation: startAlt - 350,
        verticalDescent: 350,
        runDistance: 3550, // ~3.55 km
        routePoints: mockPoints
    )
}

// 1 week ago - Run 3
var mockRun9: Run {
    let startTime = Date().addingTimeInterval(-604800 - 10800)
    let endTime = startTime.addingTimeInterval(268) // 4 min 28 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8612
    let startLon = 147.2828
    let startAlt = 2200.0
    let totalPoints = 46
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 6) * 0.0010
        let forwardProgress = progress * 0.0050
        
        let lat = startLat - forwardProgress + lateralOffset * 0.44
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 450) + sin(progress * .pi * 10) * 14
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 268)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 22.0,
        averageSpeed: 14.5,
        startElevation: startAlt,
        endElevation: startAlt - 450,
        verticalDescent: 450,
        runDistance: 4250, // ~4.25 km
        routePoints: mockPoints
    )
}

// 1 week ago - Run 4
var mockRun10: Run {
    let startTime = Date().addingTimeInterval(-604800 - 14400)
    let endTime = startTime.addingTimeInterval(315) // 5 min 15 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8592
    let startLon = 147.2812
    let startAlt = 2200.0
    let totalPoints = 34
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 3.2) * 0.0005
        let forwardProgress = progress * 0.0034
        
        let lat = startLat - forwardProgress + lateralOffset * 0.33
        let lon = startLon + forwardProgress + lateralOffset * 0.88
        let alt = startAlt - (progress * 300) + sin(progress * .pi * 6) * 8
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 315)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 18.3,
        averageSpeed: 12.0,
        startElevation: startAlt,
        endElevation: startAlt - 300,
        verticalDescent: 300,
        runDistance: 3400, // ~3.4 km
        routePoints: mockPoints
    )
}

// 2 weeks ago - Run 1
var mockRun11: Run {
    let startTime = Date().addingTimeInterval(-1209600 - 5400)
    let endTime = startTime.addingTimeInterval(308) // 5 min 8 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8602
    let startLon = 147.2819
    let startAlt = 2050.0
    let totalPoints = 37
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 4.2) * 0.0006
        let forwardProgress = progress * 0.0037
        
        let lat = startLat - forwardProgress + lateralOffset * 0.36
        let lon = startLon + forwardProgress + lateralOffset * 0.92
        let alt = startAlt - (progress * 350) + sin(progress * .pi * 7) * 9
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 308)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 17.5,
        averageSpeed: 11.5,
        startElevation: startAlt,
        endElevation: startAlt - 350,
        verticalDescent: 350,
        routePoints: mockPoints
    )
}

// 2 weeks ago - Run 2
var mockRun12: Run {
    let startTime = Date().addingTimeInterval(-1209600 - 9000)
    let endTime = startTime.addingTimeInterval(288) // 4 min 48 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8608
    let startLon = 147.2824
    let startAlt = 2050.0
    let totalPoints = 41
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 4.5) * 0.0007
        let forwardProgress = progress * 0.0043
        
        let lat = startLat - forwardProgress + lateralOffset * 0.39
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 400) + sin(progress * .pi * 8) * 11
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 288)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 20.2,
        averageSpeed: 13.2,
        startElevation: startAlt,
        endElevation: startAlt - 400,
        verticalDescent: 400,
        routePoints: mockPoints
    )
}

// 1 month ago - Run 1
var mockRun13: Run {
    let startTime = Date().addingTimeInterval(-2592000 - 3600)
    let endTime = startTime.addingTimeInterval(318) // 5 min 18 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8590
    let startLon = 147.2808
    let startAlt = 1900.0
    let totalPoints = 33
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 3.7) * 0.0005
        let forwardProgress = progress * 0.0032
        
        let lat = startLat - forwardProgress + lateralOffset * 0.31
        let lon = startLon + forwardProgress + lateralOffset * 0.83
        let alt = startAlt - (progress * 300) + sin(progress * .pi * 5) * 7
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 318)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 16.0,
        averageSpeed: 10.8,
        startElevation: startAlt,
        endElevation: startAlt - 300,
        verticalDescent: 300,
        routePoints: mockPoints
    )
}

// 1 month ago - Run 2
var mockRun14: Run {
    let startTime = Date().addingTimeInterval(-2592000 - 7200)
    let endTime = startTime.addingTimeInterval(302) // 5 min 2 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8597
    let startLon = 147.2816
    let startAlt = 1900.0
    let totalPoints = 39
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 4.3) * 0.0006
        let forwardProgress = progress * 0.0038
        
        let lat = startLat - forwardProgress + lateralOffset * 0.35
        let lon = startLon + forwardProgress + lateralOffset * 0.94
        let alt = startAlt - (progress * 350) + sin(progress * .pi * 7) * 9
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 302)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 18.8,
        averageSpeed: 12.3,
        startElevation: startAlt,
        endElevation: startAlt - 350,
        verticalDescent: 350,
        routePoints: mockPoints
    )
}

// 1 month ago - Run 3
var mockRun15: Run {
    let startTime = Date().addingTimeInterval(-2592000 - 10800)
    let endTime = startTime.addingTimeInterval(292) // 4 min 52 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8604
    let startLon = 147.2821
    let startAlt = 1900.0
    let totalPoints = 42
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 5.2) * 0.0008
        let forwardProgress = progress * 0.0044
        
        let lat = startLat - forwardProgress + lateralOffset * 0.40
        let lon = startLon + forwardProgress + lateralOffset
        let alt = startAlt - (progress * 400) + sin(progress * .pi * 8) * 11
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 292)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 19.7,
        averageSpeed: 13.0,
        startElevation: startAlt,
        endElevation: startAlt - 400,
        verticalDescent: 400,
        routePoints: mockPoints
    )
}

// 2 months ago - Run 1
var mockRun16: Run {
    let startTime = Date().addingTimeInterval(-5184000 - 5400)
    let endTime = startTime.addingTimeInterval(325) // 5 min 25 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8587
    let startLon = 147.2806
    let startAlt = 1850.0
    let totalPoints = 31
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = cos(progress * .pi * 3.5) * 0.0005
        let forwardProgress = progress * 0.0031
        
        let lat = startLat - forwardProgress + lateralOffset * 0.30
        let lon = startLon + forwardProgress + lateralOffset * 0.81
        let alt = startAlt - (progress * 300) + sin(progress * .pi * 5) * 6
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 325)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 15.5,
        averageSpeed: 10.2,
        startElevation: startAlt,
        endElevation: startAlt - 300,
        verticalDescent: 300,
        routePoints: mockPoints
    )
}

// 2 months ago - Run 2
var mockRun17: Run {
    let startTime = Date().addingTimeInterval(-5184000 - 9000)
    let endTime = startTime.addingTimeInterval(312) // 5 min 12 sec
    
    var mockPoints: [RoutePoint] = []
    let startLat = -36.8594
    let startLon = 147.2813
    let startAlt = 1850.0
    let totalPoints = 36
    
    for i in 0..<totalPoints {
        let progress = Double(i) / Double(totalPoints - 1)
        let lateralOffset = sin(progress * .pi * 4.1) * 0.0006
        let forwardProgress = progress * 0.0036
        
        let lat = startLat - forwardProgress + lateralOffset * 0.34
        let lon = startLon + forwardProgress + lateralOffset * 0.90
        let alt = startAlt - (progress * 350) + sin(progress * .pi * 6) * 8
        
        mockPoints.append(RoutePoint(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            timestamp: startTime.addingTimeInterval(progress * 312)
        ))
    }
    
    return Run(
        startTime: startTime,
        endTime: endTime,
        topSpeed: 17.8,
        averageSpeed: 11.7,
        startElevation: startAlt,
        endElevation: startAlt - 350,
        verticalDescent: 350,
        routePoints: mockPoints
    )
}

// Array of all sample runs
let sampleMockRuns: [Run] = [
    mockRun1,
    mockRun2,
    mockRun3,
    mockRun4,
    mockRun5,
    mockRun6,
    mockRun7,
    mockRun8,
    mockRun9,
    mockRun10,
    mockRun11,
    mockRun12,
    mockRun13,
    mockRun14,
    mockRun15,
    mockRun16,
    mockRun17
]

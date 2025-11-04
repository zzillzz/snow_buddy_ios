//
//  TrackingManagerTests.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 1/11/2025.
//

import XCTest
import CoreLocation
import SwiftData
@testable import snow_buddy

@MainActor
final class TrackingManagerTests: XCTestCase {
    
    var trackingManager: TrackingManager!
    var mockLocationManager: MockLocationManager!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Setup SwiftData model context
        let schema = Schema([Run.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(container)
        
        // Create mock location manager
        mockLocationManager = MockLocationManager()
        
        // Inject mock into tracking manager
        trackingManager = TrackingManager(locationManager: mockLocationManager)
        trackingManager.setModelContext(modelContext)
    }
    
    override func tearDown() {
        trackingManager = nil
        mockLocationManager = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - Recording State Tests
    
    func testStartRecording() {
        // Given
        XCTAssertFalse(trackingManager.isRecording)
        
        // When
        trackingManager.startRecording()
        
        // Then
        XCTAssertTrue(trackingManager.isRecording)
        XCTAssertEqual(trackingManager.completedRuns.count, 0)
        XCTAssertEqual(trackingManager.totalDistance, 0.0)
        XCTAssertEqual(trackingManager.currentSpeed, 0.0)
        XCTAssertEqual(trackingManager.averageSpeed, 0.0)
        XCTAssertEqual(trackingManager.topSpeed, 0.0)
    }
    
    func testStopRecording() {
        // Given
        trackingManager.startRecording()
        XCTAssertTrue(trackingManager.isRecording)
        
        // When
        trackingManager.stopRecording()
        
        // Then
        XCTAssertFalse(trackingManager.isRecording)
    }
    
    func testStartRecordingWhenAlreadyRecording() {
        // Given
        trackingManager.startRecording()
        let initialSpeed = trackingManager.currentSpeed
        
        // When
        trackingManager.startRecording() // Try to start again
        
        // Then
        XCTAssertTrue(trackingManager.isRecording)
        XCTAssertEqual(trackingManager.currentSpeed, initialSpeed)
    }
    
    func testStopRecordingWhenNotRecording() {
        // Given
        XCTAssertFalse(trackingManager.isRecording)
        
        // When
        trackingManager.stopRecording()
        
        // Then
        XCTAssertFalse(trackingManager.isRecording)
    }
    
    // MARK: - Distance Calculation Tests
    
    func testDistance3D_HorizontalOnly() {
        // Given
        let start = CLLocation(latitude: 0, longitude: 0)
        let end = CLLocation(latitude: 0, longitude: 0.001) // ~111m horizontal
        
        // When
        let distance = trackingManager.distance3D(from: start, to: end)
        
        // Then
        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 120)
    }
    
    func testDistance3D_VerticalOnly() {
        // Given
        let start = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 1000,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        let end = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 900,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        
        // When
        let distance = trackingManager.distance3D(from: start, to: end)
        
        // Then
        XCTAssertEqual(distance, 100, accuracy: 0.1)
    }
    
    func testDistance3D_BothHorizontalAndVertical() {
        // Given - 3-4-5 triangle: 30m horizontal, 40m vertical = 50m diagonal
        let start = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 1000,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        let end = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0.00027, longitude: 0), // ~30m
            altitude: 960,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        
        // When
        let distance = trackingManager.distance3D(from: start, to: end)
        
        // Then
        XCTAssertEqual(distance, 50, accuracy: 5) // Allow some GPS calculation variance
    }
    
    // MARK: - Location Processing Tests
    
    func testLocationUpdate_ValidLocation() {
        // Given
        trackingManager.startRecording()
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        
        // Then
        XCTAssertEqual(trackingManager.currentElevation, 1000)
    }
    
    func testLocationUpdate_InvalidHorizontalAccuracy() {
        // Given
        trackingManager.startRecording()
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 100, // Too inaccurate
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        let initialElevation = trackingManager.currentElevation
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        
        // Then - Should be rejected
        XCTAssertEqual(trackingManager.currentElevation, initialElevation)
    }
    
    func testLocationUpdate_InvalidVerticalAccuracy() {
        // Given
        trackingManager.startRecording()
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 10,
            verticalAccuracy: 100, // Too inaccurate
            timestamp: Date()
        )
        
        let initialElevation = trackingManager.currentElevation
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        
        // Then - Should be rejected
        XCTAssertEqual(trackingManager.currentElevation, initialElevation)
    }
    
    func testLocationUpdate_StaleTimestamp() {
        // Given
        trackingManager.startRecording()
        let staleDate = Date().addingTimeInterval(-10) // 10 seconds old
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: staleDate
        )
        
        let initialElevation = trackingManager.currentElevation
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        
        // Then - Should be rejected
        XCTAssertEqual(trackingManager.currentElevation, initialElevation)
    }
    
    func testLocationUpdate_NotRecording() {
        // Given
        XCTAssertFalse(trackingManager.isRecording)
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        
        // Then - Should be ignored
        XCTAssertEqual(trackingManager.currentElevation, 0)
    }
    
    // MARK: - Speed Calculation Tests
    
    func testSpeedCalculation_TwoLocations() async {
        // Given
        trackingManager.startRecording()
        
        let location1 = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Move 20m in 0.2s = 100 m/s = 360 km/h (unrealistic but tests the calc)
        let location2 = createMockLocation(
            latitude: 47.60638,
            longitude: -122.3321,
            altitude: 995,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location1])
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location2])
        
        // Then
        XCTAssertGreaterThan(trackingManager.currentSpeed, 0)
    }
    
    func testSpeedCalculation_SmoothedOverMultipleReadings() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()
        
        // Simulate 5 readings with varying speeds
        let speeds: [Double] = [5.0, 7.0, 6.0, 8.0, 6.0] // m/s
        
        for (index, targetSpeed) in speeds.enumerated() {
            let distance = targetSpeed * 0.1 // Move for 0.1 seconds
            let location = createMockLocation(
                latitude: 47.6062 + (Double(index) * 0.0001),
                longitude: -122.3321,
                altitude: 1000 - Double(index * 2),
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                timestamp: currentTime
            )
            
            trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
            currentTime = currentTime.addingTimeInterval(0.1)
            
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Then - Speed should be smoothed (average of window)
        XCTAssertGreaterThan(trackingManager.currentSpeed, 0)
    }
    
    // MARK: - Run Detection Tests
    
    func testRunDetection_StartsWhenSpeedAndDescentMet() async {
        // Given
        trackingManager.startRecording()
        
        let location1 = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Fast speed + descending
        let location2 = createMockLocation(
            latitude: 47.6064,
            longitude: -122.3321,
            altitude: 995, // Descending
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        
        // When
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location1])
        try? await Task.sleep(nanoseconds: 100_000_000)
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location2])
        
        // Then
        // Should start a run (we can't test private isInRun, but can check side effects)
        XCTAssertGreaterThan(trackingManager.currentSpeed, 0)
    }
    
    func testRunDetection_DoesNotStartWhenSpeedTooLow() async {
        // Given
        trackingManager.startRecording()
        
        let baseTime = Date()
        
        // Send an initial location to prime the system
        let primeLocation = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: baseTime.addingTimeInterval(-1.0) // 1 second before
        )
        
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [primeLocation])
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Now send the actual test locations
        let location1 = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: baseTime
        )
        
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location1])
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        // Small movement: ~1.1m over 0.6s = ~1.8 m/s (below threshold)
        let location2 = createMockLocation(
            latitude: 47.60621,
            longitude: -122.3321,
            altitude: 999,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: baseTime.addingTimeInterval(0.6)
        )
        
        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location2])
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        print("📊 Current speed: \(trackingManager.currentSpeed) m/s (\(trackingManager.currentSpeed * 3.6) km/h)")
        XCTAssertLessThan(trackingManager.currentSpeed, 2.0, "Speed should be below run start threshold (got \(trackingManager.currentSpeed) m/s)")
        XCTAssertEqual(trackingManager.completedRuns.count, 0, "No run should have been started with low speed")
    }
    
    // MARK: - Distance Tracking Tests
    
    func testDistanceTracking_AccumulatesDuringRun() async {
        // Given
        trackingManager.startRecording()
        
        // Create a run with enough speed to trigger run detection
        let locations = createSnowboardingRun(
            startLat: 47.6062,
            startLon: -122.3321,
            startAlt: 1000,
            endAlt: 900,
            duration: 60,
            points: 10
        )
        
        print("🧪 Created \(locations.count) locations for run")
        
        // When - Send locations with real-time timestamps
        for (index, location) in locations.enumerated() {
            // Use current time for each location to avoid staleness
            let updatedLocation = createMockLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                timestamp: Date() // Current time, not past time
            )
            
            print("🧪 Sending location \(index + 1)/\(locations.count): alt=\(updatedLocation.altitude)m")
            
            mockLocationManager.simulateLocationUpdate([updatedLocation])
            
            // Wait for processing AND simulate real time passing
            try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
            
            print("   📊 Speed: \(String(format: "%.1f", trackingManager.currentSpeed * 3.6)) km/h, Distance: \(trackingManager.totalDistance)m")
        }
        
        // Wait for final processing
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        print("🧪 Final state:")
        print("   Total distance: \(trackingManager.totalDistance)m")
        print("   Completed runs: \(trackingManager.completedRuns.count)")
        print("   Current speed: \(trackingManager.currentSpeed * 3.6) km/h")
        
        XCTAssertGreaterThan(trackingManager.totalDistance, 0, "Distance should have been tracked during the run")
    }
    
//    func testDistanceTracking_RejectsUnrealisticJumps() async {
//        // Given
//        trackingManager.startRecording()
//        
//        let location1 = createMockLocation(
//            latitude: 47.6062,
//            longitude: -122.3321,
//            altitude: 1000,
//            horizontalAccuracy: 5,
//            verticalAccuracy: 5,
//            timestamp: Date()
//        )
//        
//        try? await Task.sleep(nanoseconds: 100_000_000)
//        
//        // Unrealistic GPS jump (100m+ in 0.1s)
//        let location2 = createMockLocation(
//            latitude: 47.607,
//            longitude: -122.3321,
//            altitude: 995,
//            horizontalAccuracy: 5,
//            verticalAccuracy: 5,
//            timestamp: Date()
//        )
//        
//        // When
//        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location1])
//        let distanceAfterFirst = trackingManager.totalDistance
//        
//        trackingManager.locationManager(CLLocationManager(), didUpdateLocations: [location2])
//        let distanceAfterSecond = trackingManager.totalDistance
//        
//        // Then - Distance shouldn't change much due to unrealistic jump
//        XCTAssertEqual(distanceAfterFirst, distanceAfterSecond, accuracy: 10)
//    }
    
    // MARK: - Session Management Tests
    
    func testSessionReset_ClearsAllData() {
        // Given
        trackingManager.startRecording()
        // Simulate some data
        trackingManager.simulateRun()
        
        // When
        trackingManager.stopRecording()
        trackingManager.startRecording()
        
        // Then
        XCTAssertEqual(trackingManager.completedRuns.count, 0)
        XCTAssertEqual(trackingManager.totalDistance, 0.0)
        XCTAssertEqual(trackingManager.currentSpeed, 0.0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockLocation(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance = 0,
        horizontalAccuracy: CLLocationAccuracy = 5,
        verticalAccuracy: CLLocationAccuracy = 5,
        timestamp: Date
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: timestamp
        )
    }
    
    private func createSnowboardingRun(
        startLat: CLLocationDegrees,
        startLon: CLLocationDegrees,
        startAlt: CLLocationDistance,
        endAlt: CLLocationDistance,
        duration: TimeInterval,
        points: Int
    ) -> [CLLocation] {
        var locations: [CLLocation] = []
        
        let altitudeStep = (startAlt - endAlt) / Double(points - 1)
        
        // Move south (decreasing latitude) to simulate movement
        // At 47° latitude, 0.0001° ≈ 11 meters
        let latitudeStep = 0.0001 * 5 // ~55 meters per step
        
        for i in 0..<points {
            let progress = Double(i) / Double(points - 1)
            
            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: startLat - (latitudeStep * Double(i)),
                    longitude: startLon
                ),
                altitude: startAlt - (altitudeStep * Double(i)),
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                timestamp: Date() // Will be overridden in test
            )
            
            locations.append(location)
        }
        
        // Verify the run will trigger detection
        if locations.count >= 2 {
            let dist = locations[0].distance(from: locations[1])
            let timeStep = duration / Double(points - 1)
            let speed = dist / timeStep
            print("🧪 Helper: Distance between points: \(dist)m, Time step: \(timeStep)s, Expected speed: \(speed * 3.6) km/h")
        }
        
        return locations
    }
}

// MARK: - Mock CLLocationManager (for future use)

class MockCLLocationManager: CLLocationManager {
    var mockLocations: [CLLocation] = []
    var updateHandler: (([CLLocation]) -> Void)?
    
    func simulateLocationUpdate() {
        updateHandler?(mockLocations)
    }
}

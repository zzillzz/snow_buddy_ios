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

    // MARK: - Initialization Tests

    func testInitialization_StartsLocationTracking() {
        // Then
        XCTAssertTrue(mockLocationManager.isUpdatingLocation, "Location tracking should start on initialization")
        XCTAssertTrue(mockLocationManager.authorizationRequested, "Authorization should be requested")
    }

    func testInitialization_SetsUpLocationManager() {
        // Then
        XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyBest)
        XCTAssertEqual(mockLocationManager.activityType, .other)
        XCTAssertFalse(mockLocationManager.pausesLocationUpdatesAutomatically)
        XCTAssertTrue(mockLocationManager.allowsBackgroundLocationUpdates)
        XCTAssertTrue(mockLocationManager.showsBackgroundLocationIndicator)
        XCTAssertEqual(mockLocationManager.distanceFilter, 5)
    }

    // MARK: - Recording State Tests

    func testStartRecording_InitializesState() {
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
        XCTAssertEqual(trackingManager.currentRoutePoints.count, 0)
        XCTAssertEqual(trackingManager.currentRouteCoordinates.count, 0)
    }

    func testStopRecording_EndsRecording() {
        // Given
        trackingManager.startRecording()
        XCTAssertTrue(trackingManager.isRecording)

        // When
        trackingManager.stopRecording()

        // Then
        XCTAssertFalse(trackingManager.isRecording)
    }

    func testStartRecording_WhenAlreadyRecording_DoesNotReset() {
        // Given
        trackingManager.startRecording()
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            timestamp: Date()
        )
        mockLocationManager.simulateLocationUpdate([location])

        let initialSpeed = trackingManager.currentSpeed

        // When
        trackingManager.startRecording() // Try to start again

        // Then
        XCTAssertTrue(trackingManager.isRecording)
        XCTAssertEqual(trackingManager.currentSpeed, initialSpeed)
    }

    func testStopRecording_WhenNotRecording_DoesNothing() {
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
        XCTAssertEqual(distance, 50, accuracy: 5)
    }

    // MARK: - Location Validation Tests

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
        mockLocationManager.simulateLocationUpdate([location])

        // Then
        XCTAssertEqual(trackingManager.currentElevation, 1000, accuracy: 5) // Allow Kalman filter variance
    }

    func testLocationUpdate_InvalidHorizontalAccuracy_IsRejected() {
        // Given
        trackingManager.startRecording()
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 100, // Too inaccurate (>50m threshold)
            verticalAccuracy: 10,
            timestamp: Date()
        )

        let initialElevation = trackingManager.currentElevation

        // When
        mockLocationManager.simulateLocationUpdate([location])

        // Then - Should be rejected
        XCTAssertEqual(trackingManager.currentElevation, initialElevation)
    }

    func testLocationUpdate_InvalidVerticalAccuracy_IsRejected() {
        // Given
        trackingManager.startRecording()
        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            horizontalAccuracy: 10,
            verticalAccuracy: 100, // Too inaccurate (>50m threshold)
            timestamp: Date()
        )

        let initialElevation = trackingManager.currentElevation

        // When
        mockLocationManager.simulateLocationUpdate([location])

        // Then - Should be rejected
        XCTAssertEqual(trackingManager.currentElevation, initialElevation)
    }

    func testLocationUpdate_StaleTimestamp_IsRejected() {
        // Given
        trackingManager.startRecording()
        let staleDate = Date().addingTimeInterval(-10) // 10 seconds old (>5s threshold)
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
        mockLocationManager.simulateLocationUpdate([location])

        // Then - Should be rejected
        XCTAssertEqual(trackingManager.currentElevation, initialElevation)
    }

    func testLocationUpdate_UpdatesUserLocationEvenWhenNotRecording() async {
        // Given
        XCTAssertFalse(trackingManager.isRecording)
        XCTAssertNil(trackingManager.userLocation)

        let location = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            timestamp: Date()
        )

        // When
        mockLocationManager.simulateLocationUpdate([location])

        // Wait for async main queue update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then - userLocation should be updated even when not recording
        XCTAssertNotNil(trackingManager.userLocation)
        if let userLocation = trackingManager.userLocation {
            XCTAssertEqual(userLocation.latitude, 47.6062, accuracy: 0.0001)
            XCTAssertEqual(userLocation.longitude, -122.3321, accuracy: 0.0001)
        }

        // But elevation tracking should not happen
        XCTAssertEqual(trackingManager.currentElevation, 0)
    }

    // MARK: - Speed Calculation Tests

    func testSpeedCalculation_FromTwoLocations() async {
        // Given
        trackingManager.startRecording()

        let location1 = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            timestamp: Date()
        )

        mockLocationManager.simulateLocationUpdate([location1])

        // Wait for realistic time interval
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Move ~22m in 0.5s = ~44 m/s = ~158 km/h
        let location2 = createMockLocation(
            latitude: 47.60640, // ~20m north
            longitude: -122.3321,
            altitude: 995,
            timestamp: Date()
        )

        // When
        mockLocationManager.simulateLocationUpdate([location2])

        // Then
        XCTAssertGreaterThan(trackingManager.currentSpeed, 0, "Speed should be calculated from location changes")
    }

    func testSpeedCalculation_IsSmoothedOverWindow() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()

        // Simulate several location updates with varying speeds
        // Speed smoothing window is 5, so after 5 updates the speed should be averaged
        for i in 0..<6 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0001), // ~11m per step
                longitude: -122.3321,
                altitude: 1000 - Double(i * 2),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then - Speed should be smoothed (not equal to instant speed)
        XCTAssertGreaterThan(trackingManager.currentSpeed, 0, "Smoothed speed should be greater than 0")
    }

    func testSpeedCalculation_NegativeSpeed_IsClamped() async {
        // Given
        trackingManager.startRecording()

        let location1 = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            timestamp: Date()
        )

        mockLocationManager.simulateLocationUpdate([location1])
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Same location (no movement)
        let location2 = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            timestamp: Date()
        )

        // When
        mockLocationManager.simulateLocationUpdate([location2])

        // Then
        XCTAssertGreaterThanOrEqual(trackingManager.currentSpeed, 0, "Speed should never be negative")
    }

    // MARK: - Run Detection Tests - Sustained Speed

    func testRunDetection_RequiresSustainedSpeed() async {
        // Given - Run start speed is 3.5 m/s (~12.6 km/h), requires 3 consecutive readings
        trackingManager.startRecording()
        var currentTime = Date()

        // Send initial location to establish baseline (speed will be 0 for this one)
        let initialLocation = createMockLocation(
            latitude: 47.6062,
            longitude: -122.3321,
            altitude: 1000,
            timestamp: currentTime
        )
        mockLocationManager.simulateLocationUpdate([initialLocation])
        currentTime = currentTime.addingTimeInterval(1.0)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Send 2 fast readings (not enough for sustained threshold of 3)
        for i in 1..<3 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0005), // ~55m per step
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then - Should NOT have started a run yet (only 2 fast speed readings)
        XCTAssertEqual(trackingManager.currentRoutePoints.count, 0, "Run should not start with only 2 fast speed readings")

        // Now send 3rd consecutive fast reading
        let location4 = createMockLocation(
            latitude: 47.6062 + (Double(3) * 0.0005),
            longitude: -122.3321,
            altitude: 1000 - Double(3 * 5),
            timestamp: currentTime
        )

        // When
        mockLocationManager.simulateLocationUpdate([location4])
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - Run should now start (3 consecutive fast speed readings)
        XCTAssertGreaterThan(trackingManager.currentRoutePoints.count, 0, "Run should start after 3 consecutive fast speed readings")
    }

//    func testRunDetection_ResetsCounterWhenSpeedDrops() async {
//        // Given - Speed smoothing window is 5, so we need multiple slow readings to drop the average
//        trackingManager.startRecording()
//        var currentTime = Date()
//
//        // Send initial baseline location
//        var currentLat = 47.6062
//        let initialLocation = createMockLocation(
//            latitude: currentLat,
//            longitude: -122.3321,
//            altitude: 1000,
//            timestamp: currentTime
//        )
//        mockLocationManager.simulateLocationUpdate([initialLocation])
//        currentTime = currentTime.addingTimeInterval(1.0)
//        try? await Task.sleep(nanoseconds: 100_000_000)
//
//        // Send 2 fast readings (counter = 1, then 2)
//        for i in 1..<3 {
//            currentLat += 0.0005 // ~55m per step
//            let location = createMockLocation(
//                latitude: currentLat,
//                longitude: -122.3321,
//                altitude: 1000 - Double(i * 5),
//                timestamp: currentTime
//            )
//
//            mockLocationManager.simulateLocationUpdate([location])
//            currentTime = currentTime.addingTimeInterval(1.0)
//            try? await Task.sleep(nanoseconds: 100_000_000)
//        }
//
//        // Now slow down - send multiple slow readings to bring smoothed speed below threshold
//        // Speed smoothing uses moving average of last 5 readings, so we need several slow ones
//        for _ in 0..<4 {
//            currentLat += 0.00001 // ~1.1m per step = ~1.1 m/s (below 3.5 m/s threshold)
//            let location = createMockLocation(
//                latitude: currentLat,
//                longitude: -122.3321,
//                altitude: 1000 - Double(2 * 5),
//                timestamp: currentTime
//            )
//
//            mockLocationManager.simulateLocationUpdate([location])
//            currentTime = currentTime.addingTimeInterval(1.0)
//            try? await Task.sleep(nanoseconds: 100_000_000)
//        }
//
//        // Then send ONE fast reading (counter should only be at 1 after reset)
//        currentLat += 0.0005 // Fast movement again
//        let fastLocation = createMockLocation(
//            latitude: currentLat,
//            longitude: -122.3321,
//            altitude: 1000 - Double(2 * 5),
//            timestamp: currentTime
//        )
//
//        // When
//        mockLocationManager.simulateLocationUpdate([fastLocation])
//        try? await Task.sleep(nanoseconds: 100_000_000)
//
//        // Then - Should NOT have started run (counter was reset, only 1 fast reading after reset)
//        XCTAssertEqual(trackingManager.currentRoutePoints.count, 0, "Counter should reset when speed drops")
//    }

    func testRunDetection_DoesNotStartWhenSpeedTooLow() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()

        // Send multiple slow readings (below 3.5 m/s threshold)
        for i in 0..<5 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.00003), // Very small movement = ~3.3 m/s
                longitude: -122.3321,
                altitude: 1000 - Double(i * 1),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then
        XCTAssertEqual(trackingManager.currentRoutePoints.count, 0, "No run should start with consistently low speed")
        XCTAssertEqual(trackingManager.completedRuns.count, 0)
    }

    // MARK: - Run Validation Tests

    func testRunValidation_MinimumDuration() async {
        // Given - Minimum duration is 10 seconds
        trackingManager.startRecording()
        var currentTime = Date()

        // Start a run with 3 fast readings
        for i in 0..<3 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0005),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Run for only 5 more seconds (total 8 seconds)
        for i in 3..<8 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0005),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // When - Stop recording (which will try to end the run)
        trackingManager.stopRecording()

        // Then - Run should be rejected for being too short
        XCTAssertEqual(trackingManager.completedRuns.count, 0, "Run should be rejected if duration < 10 seconds")
    }

    func testRunValidation_MinimumDistance() async {
        // Given - Minimum distance is 50 meters
        trackingManager.startRecording()
        var currentTime = Date()

        // Start a run with 3 fast readings
        for i in 0..<3 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0001), // ~11m per step
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Continue for enough time but short distance (total ~33m)
        for i in 3..<15 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(3) * 0.0001), // Stay at same position
                longitude: -122.3321,
                altitude: 1000 - Double(3 * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // When - Stop recording
        trackingManager.stopRecording()

        // Then - Run should be rejected for insufficient distance
        XCTAssertEqual(trackingManager.completedRuns.count, 0, "Run should be rejected if distance < 50 meters")
    }

//    func testRunValidation_ValidRun_IsSaved() async {
//        // Given - Create a valid run: 3+ fast readings, 10+ seconds, 50+ meters
//        trackingManager.startRecording()
//        var currentTime = Date()
//
//        // Send 15 locations over 15 seconds, covering ~165 meters
//        for i in 0..<15 {
//            let location = createMockLocation(
//                latitude: 47.6062 + (Double(i) * 0.0001), // ~11m per step = 154m total horizontal
//                longitude: -122.3321,
//                altitude: 1000 - Double(i * 5), // 70m vertical descent
//                timestamp: currentTime
//            )
//
//            mockLocationManager.simulateLocationUpdate([location])
//            currentTime = currentTime.addingTimeInterval(1.0)
//            try? await Task.sleep(nanoseconds: 100_000_000)
//        }
//
//        // Verify run started
//        XCTAssertGreaterThan(trackingManager.currentRoutePoints.count, 0, "Run should have started")
//
//        // When - Stop recording to end the active run
//        trackingManager.stopRecording()
//
//        // Then - Run should be saved if it passed validation
//        XCTAssertGreaterThanOrEqual(trackingManager.completedRuns.count, 1, "Valid run should be saved")
//
//        if let run = trackingManager.completedRuns.first {
//            XCTAssertGreaterThanOrEqual(run.duration, 10.0, "Run duration should be at least 10 seconds")
//            XCTAssertGreaterThanOrEqual(run.runDistance, 50.0, "Run distance should be at least 50 meters")
//        }
//    }

    // MARK: - Run Tracking Tests

    func testRunTracking_AccumulatesDistance() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()

        // Send locations to start and track a run
        for i in 0..<10 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0002), // ~22m per step
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then
        XCTAssertGreaterThan(trackingManager.totalDistance, 0, "Distance should accumulate during run")
    }

    func testRunTracking_TracksRoutePoints() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()

        // Start a run (3 consecutive fast readings)
        for i in 0..<3 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0005),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Continue run
        for i in 3..<8 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0005),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then
        XCTAssertGreaterThan(trackingManager.currentRoutePoints.count, 0, "Route points should be tracked")
        XCTAssertEqual(trackingManager.currentRoutePoints.count, trackingManager.currentRouteCoordinates.count,
                      "Route points and coordinates should match")
    }

    func testRunTracking_RecordsTopSpeed() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()

        // Start run with moderate speed
        for i in 0..<5 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0003),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        let topSpeedAfterModerate = trackingManager.topSpeed

        // Now go faster
        for i in 5..<8 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.001), // Much faster
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then
        XCTAssertGreaterThan(trackingManager.topSpeed, topSpeedAfterModerate, "Top speed should be updated")
    }

    func testRunTracking_RejectsUnrealisticDistanceJumps() async {
        // Given
        trackingManager.startRecording()
        var currentTime = Date()

        // Start normal run
        for i in 0..<5 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0001),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        let distanceBeforeJump = trackingManager.totalDistance

        // Send unrealistic GPS jump (>50m threshold)
        let jumpLocation = createMockLocation(
            latitude: 47.61, // ~440m jump
            longitude: -122.3321,
            altitude: 980,
            timestamp: currentTime
        )

        mockLocationManager.simulateLocationUpdate([jumpLocation])
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - Distance should not include the unrealistic jump
        let distanceAfterJump = trackingManager.totalDistance
        XCTAssertLessThan(distanceAfterJump - distanceBeforeJump, 50,
                         "Unrealistic distance jumps (>50m) should be rejected")
    }

    // MARK: - Session Management Tests

    func testSessionReset_ClearsAllTrackingData() {
        // Given
        trackingManager.startRecording()
        trackingManager.simulateRun()

        XCTAssertGreaterThan(trackingManager.completedRuns.count, 0)

        // When
        trackingManager.stopRecording()
        trackingManager.startRecording()

        // Then - All session data should be reset
        XCTAssertEqual(trackingManager.completedRuns.count, 0)
        XCTAssertEqual(trackingManager.totalDistance, 0.0)
        XCTAssertEqual(trackingManager.currentSpeed, 0.0)
        XCTAssertEqual(trackingManager.averageSpeed, 0.0)
        XCTAssertEqual(trackingManager.topSpeed, 0.0)
        XCTAssertEqual(trackingManager.currentRoutePoints.count, 0)
        XCTAssertEqual(trackingManager.currentRouteCoordinates.count, 0)
    }

    func testStopRecording_EndsActiveRun() async {
        // Given - Start a valid run
        trackingManager.startRecording()
        var currentTime = Date()

        for i in 0..<15 {
            let location = createMockLocation(
                latitude: 47.6062 + (Double(i) * 0.0002),
                longitude: -122.3321,
                altitude: 1000 - Double(i * 5),
                timestamp: currentTime
            )

            mockLocationManager.simulateLocationUpdate([location])
            currentTime = currentTime.addingTimeInterval(1.0)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        XCTAssertGreaterThan(trackingManager.currentRoutePoints.count, 0, "Run should be active")

        // When
        trackingManager.stopRecording()

        // Then - Run should be ended (if valid) or cleared
        XCTAssertFalse(trackingManager.isRecording)
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
}

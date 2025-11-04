//
//  SpeedTrackingManager.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 26/9/2025.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUICore
import SwiftData

class TrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager: LocationManagerProtocol
    private var runManager: RunManager?
    
    @Published var userLocation: CLLocationCoordinate2D? = nil
    
    @Published var isRecording = false
    
    @Published var currentRun: Run?
    @Published var completedRuns: [Run] = []
    
    @Published var currentSpeed: Double = 0
    @Published var currentElevation: Double = 0
    
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var averageSpeed: Double = 0
    @Published var topSpeed: Double = 0
    
    @Published var currentRoutePoints: [RoutePoint] = []
    @Published var currentRouteCoordinates: [CLLocationCoordinate2D] = []
    
    // Run detection parameters
    private var runStartSpeed: Double = 2.0 // m/s (~7 km/h)
    private var runStopSpeed: Double = 1.0 // m/s (~3.6 km/h)
    private var minDescentForRun: Double = 20.0 // meters
    private var stopTimeThreshold: TimeInterval = 30.0 // seconds
    
    private var runStartTime: Date?
    private var runStartElevation: Double?
    private var runSpeeds: [Double] = []
    private var runTopSpeed: Double = 0
    private var lastMovementTime: Date = Date()
    private var isInRun = false
    private var lastLocation: CLLocation?
    
    private var speedHistory: [Double] = []
    private let speedSmoothingWindow = 5
    
    private var kalmanLat = KalmanFilter()
    private var kalmanLon = KalmanFilter()
    private var kalmanAlt = KalmanFilter()
    
    // Default initializer uses real CLLocationManager
    convenience override init() {
        self.init(locationManager: CLLocationManager())
    }
    
    // Dependency injection initializer for testing
    init(locationManager: LocationManagerProtocol) {
        self.locationManager = locationManager
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .other

        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true

        locationManager.distanceFilter = kCLDistanceFilterNone // Update every meter
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.runManager = RunManager(modelContext: modelContext)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        currentRoutePoints.removeAll()
        currentRouteCoordinates.removeAll()
        completedRuns = []
        totalDistance = 0.0
        currentSpeed = 0.0
        averageSpeed = 0.0
        topSpeed = 0.0
        speedHistory = []
        
        kalmanLat.reset()
        kalmanLon.reset()
        kalmanAlt.reset()
        
        lastLocation = nil
        
        
        locationManager.startUpdatingLocation()
        
        print("Started recording run")
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        if isInRun {
            endCurrentRun()
        }
        
        isRecording = false
        locationManager.stopUpdatingLocation()
        
        print("Stopped recording ski session")
        print("Total runs: \(completedRuns.count)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isRecording else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }

        
        // Validate location quality
        guard isLocationValid(location) else {
            print("⚠️ Skipping invalid location")
            return
        }
        
        let filteredLat = kalmanLat.filter(location.coordinate.latitude)
        let filteredLon = kalmanLon.filter(location.coordinate.longitude)
        let filteredAlt = kalmanAlt.filter(location.altitude)
        
        let smoothedLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: filteredLat, longitude: filteredLon),
            altitude: filteredAlt,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            timestamp: location.timestamp
        )
        // let smoothedLocation = location
        
        currentElevation = smoothedLocation.altitude

        if let last = lastLocation {
            let dt = smoothedLocation.timestamp.timeIntervalSince(last.timestamp)
            if dt > 0.1 {
                // currentSpeed = max(0, distance / dt)
                currentSpeed = calculateSmoothedSpeed(from: last, to: smoothedLocation)
                print("📍 Speed: \(String(format: "%.1f", currentSpeed * 3.6)) km/h | Distance: \(String(format: "%.1f", totalDistance))m | Elevation: \(String(format: "%.1f", currentElevation))m")
            }
        } else {
            currentSpeed = 0
        }
        
        // currentSpeed = max(0, smoothedLocation.speed)
        
        guard currentSpeed >= 0 else { return }
        
        detectRunState(location: smoothedLocation)
        
        if isInRun {
            trackRunData(newLocation: smoothedLocation)
        }
        
        lastLocation = smoothedLocation
    }
    
    private func calculateSmoothedSpeed(from: CLLocation, to: CLLocation) -> Double {
        let distance = from.distance(from: to)
        let dt = to.timestamp.timeIntervalSince(from.timestamp)
        
        guard dt > 0 else { return currentSpeed }
        
        let instantSpeed = distance / dt
        
        // Add to history and keep only recent readings
        speedHistory.append(instantSpeed)
        if speedHistory.count > speedSmoothingWindow {
            speedHistory.removeFirst()
        }
        
        // Return moving average
        return speedHistory.reduce(0, +) / Double(speedHistory.count)
    }
    
    private func isLocationValid(_ location: CLLocation) -> Bool {
        // Filter out inaccurate readings
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else {
            print("⚠️ Poor horizontal accuracy: \(location.horizontalAccuracy)m")
            return false
        }
        
        guard location.verticalAccuracy >= 0 && location.verticalAccuracy < 50 else {
            print("⚠️ Poor vertical accuracy: \(location.verticalAccuracy)m")
            return false
        }
        
        // Filter out old readings
        guard abs(location.timestamp.timeIntervalSinceNow) < 5.0 else {
            print("⚠️ Stale location data")
            return false
        }
        
        return true
    }
    
    private func detectRunState(location: CLLocation) {
        let now = Date()
        
        if !isInRun {
            if shouldStartRun(location: location) {
                startNewRun(location: location)
            }
        } else {
            if currentSpeed > runStopSpeed {
                lastMovementTime = now
            } else if now.timeIntervalSince(lastMovementTime) > stopTimeThreshold {
                //if shouldEndRun(location: location) {
                endCurrentRun()
                //}
            }
        }
    }
    
    private func shouldStartRun(location: CLLocation) -> Bool {
        guard currentSpeed >= runStartSpeed else { return false }
        
        if let lastLoc = lastLocation {
            let elevationChange = lastLoc.altitude - location.altitude
            return elevationChange > 0
        }
        
        return true
    }
    
    private func shouldEndRun(location: CLLocation) -> Bool {
        // Must have been in run for minimum time
        guard let startTime = runStartTime, Date().timeIntervalSince(startTime) > 10.0 else { return false }
        
        // Check if we've had significant descent
        guard let startElevation = runStartElevation else { return false }
        let totalDescent = startElevation - location.altitude
        
        return totalDescent >= minDescentForRun
    }
    
    private func startNewRun(location: CLLocation) {
        print("Starting new run")
        
        isInRun = true
        runStartTime = Date()
        runStartElevation = location.altitude
        runSpeeds = [currentSpeed]
        runTopSpeed = currentSpeed
        lastMovementTime = Date()
        
        // Reset route tracking for new run
        currentRoutePoints.removeAll()
        currentRouteCoordinates.removeAll()
        
        // Add first point
        let firstPoint = RoutePoint(
            coordinate: location.coordinate,
            altitude: location.altitude,
            timestamp: location.timestamp
        )
        currentRoutePoints.append(firstPoint)
        currentRouteCoordinates.append(location.coordinate)

        
        print("Start elevation: \(location.altitude)m, Speed: \(currentSpeed * 3.6) km/h")
    }
    
    private func endCurrentRun() {
        guard let startTime = runStartTime, let startElevation = runStartElevation else { return }
        
        let endTime = Date()
        let averageSpeed = runSpeeds.isEmpty ? 0 : runSpeeds.reduce(0, +) / Double(runSpeeds.count)
        let verticalDescent = max(0, startElevation - currentElevation)
        
        // Only save runs that meet minimum criteria
//        guard verticalDescent >= minDescentForRun else {
//            print("⚠️ Run too short: \(verticalDescent)m descent (min: \(minDescentForRun)m)")
//            isInRun = false
//            currentRoutePoints.removeAll()
//            currentRouteCoordinates.removeAll()
//            return
//        }
        
        guard endTime.timeIntervalSince(startTime) >= 10.0 else {
            print("⚠️ Run too short: \(endTime.timeIntervalSince(startTime))s (min: 10s)")
            isInRun = false
            currentRoutePoints.removeAll()
            currentRouteCoordinates.removeAll()
            return
        }
        
        let run = Run(
            startTime: startTime,
            endTime: endTime,
            topSpeed: runTopSpeed,
            averageSpeed: averageSpeed,
            startElevation: startElevation,
            endElevation: currentElevation,
            verticalDescent: verticalDescent,
            routePoints: currentRoutePoints
        )
        
        completedRuns.append(run)
        runManager?.saveRun(run)
        
        print("🏁 Ended run #\(completedRuns.count)")
        print("Duration: \(Int(run.duration))s")
        print("Top speed: \(Int(run.topSpeedKmh)) km/h")
        print("Avg speed: \(Int(run.averageSpeedKmh)) km/h")
        print("Vertical descent: \(Int(verticalDescent))m")
        print("Route points: \(currentRoutePoints.count)")
        
        // Reset run tracking
        isInRun = false
        runStartTime = nil
        runStartElevation = nil
        runSpeeds = []
        runTopSpeed = 0
    }
    
    private func trackRunData(newLocation: CLLocation) {
        runSpeeds.append(currentSpeed)
        runTopSpeed = max(runTopSpeed, currentSpeed)
        averageSpeed = runSpeeds.isEmpty ? 0 : runSpeeds.reduce(0, +) / Double(runSpeeds.count)
        
        // Update total top speed across all runs
        let currentSessionTop = completedRuns.map { $0.topSpeed }.max() ?? 0
        topSpeed = max(currentSessionTop, runTopSpeed)
        
        // Add route point
        let routePoint = RoutePoint(
            coordinate: newLocation.coordinate,
            altitude: newLocation.altitude,
            timestamp: newLocation.timestamp
        )
        currentRoutePoints.append(routePoint)
        currentRouteCoordinates.append(newLocation.coordinate)
        
        // guard let newLocation = locations.last else { return }
        if let last = lastLocation {
            let delta = distance3D(from: last, to: newLocation)
            
            if delta > 0.1 && delta < 50 {
                totalDistance += delta
            } else if delta >= 50 {
                print("⚠️ Skipping unrealistic distance jump: \(delta)m")
            }
        }
    }
    
    func distance3D(from start: CLLocation, to end: CLLocation) -> CLLocationDistance {
        // Horizontal distance (already uses Haversine in CLLocation)
        let horizontal = start.distance(from: end)
        
        // Vertical difference
        let vertical = abs(end.altitude - start.altitude)
        
        // 3D distance using Pythagorean theorem
        let distance3D = sqrt(pow(horizontal, 2) + pow(vertical, 2))
        
        return distance3D
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    
    func simulateRun() {
        print("🏂 Starting simulate run")
        print("🏂 runManager exists: \(runManager != nil)")
        
        if runManager == nil {
            print("🏂 ERROR: runManager is nil!")
            return
        }
        
        completedRuns.append(mockRun4)
        runManager?.saveRun(mockRun4)
        
        DispatchQueue.main.async {
            print("🏂 Run saved, UI should update")
        }
    }
}

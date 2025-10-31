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
    private let locationManager = CLLocationManager()
    private var runManager: RunManager?
    
    @Published var isRecording = false
    @Published var currentRun: Run?
    @Published var completedRuns: [Run] = []
    @Published var currentSpeed: Double = 0
    @Published var currentElevation: Double = 0
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var averageSpeed: Double = 0
    @Published var topSpeed: Double = 0
    
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
    
    private var kalmanLat = KalmanFilter()
    private var kalmanLon = KalmanFilter()
    private var kalmanAlt = KalmanFilter()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 1.0 // Update every meter
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.runManager = RunManager(modelContext: modelContext)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        completedRuns = []
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
        
        if let last = lastLocation {
            let distance = smoothedLocation.distance(from: last)
            let dt = smoothedLocation.timestamp.timeIntervalSince(last.timestamp)
            if dt > 0 {
                currentSpeed = max(0, distance / dt)
            }
        } else {
            currentSpeed = 0
        }
        
        // currentSpeed = max(0, smoothedLocation.speed)
        currentElevation = smoothedLocation.altitude
        
        guard currentSpeed >= 0 else { return }
        
        detectRunState(location: smoothedLocation)
        
        if isInRun {
            trackRunData(newLocation: smoothedLocation)
        }
        
        lastLocation = smoothedLocation
        
        print("📍 Speed: \(String(format: "%.1f", currentSpeed * 3.6)) km/h | Distance: \(String(format: "%.1f", totalDistance))m | Elevation: \(String(format: "%.1f", currentElevation))m")

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
        
        print("Start elevation: \(location.altitude)m, Speed: \(currentSpeed * 3.6) km/h")
    }
    
    private func endCurrentRun() {
        guard let startTime = runStartTime, let startElevation = runStartElevation else { return }
        
        let endTime = Date()
        let averageSpeed = runSpeeds.isEmpty ? 0 : runSpeeds.reduce(0, +) / Double(runSpeeds.count)
        let verticalDescent = max(0, startElevation - currentElevation)
        
        let run = Run(
            startTime: startTime,
            endTime: endTime,
            topSpeed: runTopSpeed,
            averageSpeed: averageSpeed,
            startElevation: startElevation,
            endElevation: currentElevation,
            verticalDescent: verticalDescent
        )
        
        completedRuns.append(run)
        
        runManager?.saveRun(run)
        
        print("🏁 Ended run #\(completedRuns.count)")
        print("Duration: \(Int(run.duration))s")
        print("Top speed: \(Int(run.topSpeedKmh)) km/h")
        print("Avg speed: \(Int(run.averageSpeedKmh)) km/h")
        print("Vertical descent: \(Int(verticalDescent))m")
        
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
        topSpeed = max(completedRuns.isEmpty ? 0 : completedRuns.max(by: { $0.topSpeed < $1.topSpeed })!.topSpeed, runTopSpeed)
        
        //        guard let newLocation = locations.last else { return }
        if let last = lastLocation {
            let delta = distance3D(from: last, to: newLocation)
            if delta > 0.5 {
                totalDistance += delta
            }
        }
        
    }
    
    func distance3D(from start: CLLocation, to end: CLLocation) -> CLLocationDistance {
        let horizontal = start.distance(from: end)
        let vertical = end.altitude - start.altitude
        return sqrt(pow(horizontal, 2) + pow(vertical, 2))
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
        let startTime = Date()
        let endTime = Date().addingTimeInterval(120) // 2 minute run
        
        let run = Run(
            startTime: startTime,
            endTime: endTime,
            topSpeed: 15.0, // 54 km/h
            averageSpeed: 10.0, // 36 km/h
            startElevation: 2000,
            endElevation: 1900,
            verticalDescent: 100
        )
        
        completedRuns.append(run)
        
        runManager?.saveRun(
            startTime: startTime,
            endTime: endTime,
            topSpeed: 15.0,
            averageSpeed: 10.0,
            startElevation: 2000,
            endElevation: 1900,
            verticalDescent: 100
        )
        
        DispatchQueue.main.async {
            print("🏂 Run saved, UI should update")
        }
    }
}

//
//  MockLocationManager.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

// MockLocationManager.swift
import CoreLocation
@testable import snow_buddy

class MockLocationManager: NSObject, LocationManagerProtocol {
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var activityType: CLActivityType = .other
    var pausesLocationUpdatesAutomatically: Bool = false
    var allowsBackgroundLocationUpdates: Bool = true
    var showsBackgroundLocationIndicator: Bool = true
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    
    var isUpdatingLocation = false
    var authorizationRequested = false
    
    func requestWhenInUseAuthorization() {
        authorizationRequested = true
    }
    
    func requestAlwaysAuthorization() {
        authorizationRequested = true
    }
    
    func startUpdatingLocation() {
        isUpdatingLocation = true
    }
    
    func stopUpdatingLocation() {
        isUpdatingLocation = false
    }
    
    // Test helper to simulate location updates
    func simulateLocationUpdate(_ locations: [CLLocation]) {
        delegate?.locationManager?(CLLocationManager(), didUpdateLocations: locations)
    }
    
    // Test helper to simulate errors
    func simulateError(_ error: Error) {
        delegate?.locationManager?(CLLocationManager(), didFailWithError: error)
    }
}

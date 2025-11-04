//
//  LocationManagerProtocol.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

// LocationManagerProtocol.swift
import CoreLocation

protocol LocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var activityType: CLActivityType { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var showsBackgroundLocationIndicator: Bool { get set }
    var distanceFilter: CLLocationDistance { get set }
    
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

// Extend CLLocationManager to conform to protocol
extension CLLocationManager: LocationManagerProtocol {}

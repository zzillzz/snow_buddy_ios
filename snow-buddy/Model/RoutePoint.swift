//
//  RoutePoint.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

import Foundation
import CoreLocation

// Codable wrapper for coordinates
struct RoutePoint: Codable, Identifiable {
    var id = UUID()
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var timestamp: Date?
    
    init(latitude: Double, longitude: Double, altitude: Double? = nil, timestamp: Date? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
    
    init(coordinate: CLLocationCoordinate2D, altitude: Double? = nil, timestamp: Date? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

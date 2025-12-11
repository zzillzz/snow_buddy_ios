//
//  Resort.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import Foundation
import CoreLocation

// MARK: - Resort Model
struct Resort: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let slug: String
    let country: String
    let region: String?
    let latitude: Double
    let longitude: Double
    let elevationMeters: Int?
    let createdAt: Date

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case country
        case region
        case latitude
        case longitude
        case elevationMeters = "elevation_meters"
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Resort location as CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Resort location as CLLocation
    var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: Double(elevationMeters ?? 0),
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date()
        )
    }

    /// Formatted elevation in meters
    var elevationFormatted: String {
        guard let elevation = elevationMeters else {
            return "Unknown"
        }
        return "\(elevation)m"
    }

    /// Formatted elevation in feet
    var elevationFeetFormatted: String {
        guard let elevation = elevationMeters else {
            return "Unknown"
        }
        let feet = Int(Double(elevation) * 3.28084)
        return "\(feet)ft"
    }

    /// Full display name with region
    var displayName: String {
        if let region = region {
            return "\(name), \(region)"
        }
        return name
    }

    /// Full location string
    var locationString: String {
        if let region = region {
            return "\(region), \(country)"
        }
        return country
    }

    // MARK: - Helper Methods

    /// Calculate distance from a given location
    func distance(from location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }

    /// Formatted distance from a given location
    func distanceFormatted(from location: CLLocation) -> String {
        let distance = self.distance(from: location)
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    /// Check if resort is within a certain radius of a location
    func isNearby(to location: CLLocation, within radiusKm: Double) -> Bool {
        let distance = self.distance(from: location)
        return distance <= (radiusKm * 1000)
    }
}

// MARK: - Sample Data (for previews/testing)
extension Resort {
    static let sample = Resort(
        id: UUID(),
        name: "Whistler Blackcomb",
        slug: "whistler-blackcomb",
        country: "Canada",
        region: "British Columbia",
        latitude: 50.1163,
        longitude: -122.9574,
        elevationMeters: 2182,
        createdAt: Date()
    )

    static let sampleAustralia = Resort(
        id: UUID(),
        name: "Perisher",
        slug: "perisher",
        country: "Australia",
        region: "New South Wales",
        latitude: -36.4075,
        longitude: 148.4092,
        elevationMeters: 2054,
        createdAt: Date()
    )

    static let sampleJapan = Resort(
        id: UUID(),
        name: "Niseko",
        slug: "niseko",
        country: "Japan",
        region: "Hokkaido",
        latitude: 42.8048,
        longitude: 140.6875,
        elevationMeters: 1308,
        createdAt: Date()
    )

    static let sampleNewZealand = Resort(
        id: UUID(),
        name: "Queenstown",
        slug: "queenstown",
        country: "New Zealand",
        region: "Otago",
        latitude: -45.0312,
        longitude: 168.6626,
        elevationMeters: 1649,
        createdAt: Date()
    )
}

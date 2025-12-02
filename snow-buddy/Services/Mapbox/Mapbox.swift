//
//  Mapbox.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 1/12/2025.
//

import Foundation
import MapboxMaps
import CoreLocation
import UIKit

class MapboxService: ObservableObject {
    static let shared = MapboxService()

    private init() {
        MapboxOptions.accessToken = MapboxConfig.key
    }

    // MARK: - Helper Methods

    /// Creates a LineString from an array of CLLocationCoordinate2D
    func createLineString(from coordinates: [CLLocationCoordinate2D]) -> LineString {
        let coords = coordinates.map { LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return LineString(coords)
    }

    /// Creates a Point from CLLocationCoordinate2D
    func createPoint(from coordinate: CLLocationCoordinate2D) -> Point {
        return Point(LocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    /// Calculate camera bounds to fit all coordinates
    func cameraBounds(for coordinates: [CLLocationCoordinate2D], padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)) -> CameraOptions {
        guard !coordinates.isEmpty else {
            return CameraOptions(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoom: 1)
        }

        // Calculate bounding box
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let southwest = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
        let northeast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        let bounds = CoordinateBounds(southwest: southwest, northeast: northeast)

        return CameraOptions(
            center: CLLocationCoordinate2D(
                latitude: (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                longitude: (bounds.northeast.longitude + bounds.southwest.longitude) / 2
            )
        )
    }
}

// MARK: - Color Extensions for Styling
extension UIColor {
    static var primaryColor: UIColor {
        return UIColor(named: "PrimaryColor") ?? .systemBlue
    }

    static var tertiaryColor: UIColor {
        return UIColor(named: "TertiaryColor") ?? .systemOrange
    }
}


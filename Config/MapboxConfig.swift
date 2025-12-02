//
//  MapboxConfig.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 1/12/2025.
//
import Foundation

struct MapboxConfig {
    static var key: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "MapboxAccessToken") as? String else {
            fatalError("Mapbox key was not found in build settings")
        }
        return key
    }
    
    static var currentEnvironment: String {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        if bundleId.contains(".local") {
            return "Local"
        } else if bundleId.contains(".dev") {
            return "Development"
        } else {
            return "Production"
        }
    }
}

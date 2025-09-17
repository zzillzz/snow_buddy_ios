//
//  Config.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/9/2025.
//
import Foundation

struct SupabaseConfig {
    
    static var url: String {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String else {
            fatalError("SupabaseURL not found in build settings")
        }
        return urlString
    }
    
    static var anonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseKey") as? String else {
            fatalError("SupabaseAnonKey not found in build settings")
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

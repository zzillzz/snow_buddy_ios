//
//  Colours.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 19/9/2025.
//

import Foundation
import SwiftUICore

struct ColorConfig {
    
    // MARK: - Primary Colors
    static let white = Color(hex: "FDFFFF")
    static let grape = Color(hex: "6F2DBD")
    static let amethyst = Color(hex: "A663CC")
    static let wisteria = Color(hex: "B298DC")
    static let cardinal = Color(hex: "CA2B3B")
    
    // MARK: - UI Colors (for specific use cases)
    struct UI {
        static let headingText = grape
        static let secondary = amethyst
        static let tertiary = wisteria
        static let background = white
        static let surface = white
        static let primaryButton = cardinal
        static let backround = white
    }
    
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


func colorForRun(at index: Int) -> Color {
    let colors: [Color] = [Color("PrimaryColor"), Color("SecondaryColor"), Color("TertiaryColor")]
    return colors[index % colors.count].opacity(0.7)
}

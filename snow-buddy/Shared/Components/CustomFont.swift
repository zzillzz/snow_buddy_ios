//
//  CustomFont.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 3/10/2025.
//

import Foundation
import SwiftUICore

enum LexendWeight: String {
    case thin = "Lexend-Thin"
    case extraLight = "Lexend-ExtraLight"
    case light = "Lexend-Light"
    case regular = "Lexend-Regular"
    case medium = "Lexend-Medium"
    case semiBold = "Lexend-SemiBold"
    case bold = "Lexend-Bold"
    case extraBold = "Lexend-ExtraBold"
    case black = "Lexend-Black"
}

extension Font {
    static func lexend(_ weight: LexendWeight = .regular, size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}


struct LexendFontModifier: ViewModifier {
    var weight: LexendWeight
    var size: CGFloat
    
    func body(content: Content) -> some View {
        content.font(.lexend(weight, size: size))
    }
}

extension View {
    func lexendFont(_ weight: LexendWeight = .regular, size: CGFloat) -> some View {
        self.modifier(LexendFontModifier(weight: weight, size: size))
    }
}

//Family: Lexend Font names: ["Lexend-Regular", "Lexend-Thin", "Lexend-ExtraLight", "Lexend-Light", "Lexend-Medium", "Lexend-SemiBold", "Lexend-Bold", "Lexend-ExtraBold", "Lexend-Black"]

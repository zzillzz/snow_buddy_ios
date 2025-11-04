//
//  StatCard.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import SwiftUI

struct StatCard: View {
    var title: String
    var value: String
    var valueFont: Font = .lexend(.bold, size: 24)
    var height: CGFloat? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .lexendFont(.medium, size: 14)
                .foregroundColor(Color.gray.opacity(0.7))
            
            Text(value)
                .font(valueFont)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: height)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryColor").opacity(0.2))
        )
    }
}

struct ButtonCard: View {
    var cardColor: CustomButtonStyle = .primary
    var image: String = "chevron.right"
    var height: CGFloat? = nil
    
    private var backgroundColor: Color {
        switch cardColor {
        case .primary:
            return Color("PrimaryColor")
        case .secondary:
            return Color("SecondaryColor")
        case .tertiary:
            return Color("TertiaryColor")
        }
    }
    
    private var chevronColor: Color {
        switch cardColor {
        case .primary:
            return .black
        case .secondary:
            return .white
        case .tertiary:
            return .black
        }
    }
    
    var body: some View {
        VStack{
            Image(systemName: image)
                .foregroundStyle(chevronColor)
                .bold()
        }
        .frame(maxWidth: .leastNormalMagnitude, minHeight: .leastNormalMagnitude)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }
}

#Preview {
    StatCard(title: "Snowfall", value: "10 cm")
    ButtonCard(cardColor: .primary)
    ButtonCard(cardColor: .secondary)
    ButtonCard(cardColor: .tertiary)
}

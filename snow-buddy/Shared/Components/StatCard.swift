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
                .fill(Color("Primary").opacity(0.2))
        )
    }
}
#Preview {
    StatCard(title: "Snowfall", value: "10 cm")
}

//
//  BuySeasonPassCard.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/11/2025.
//

import SwiftUI

struct BuySeasonPassCard: View {
    var action: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Season Pass")
                        .lexendFont(.bold, size: 24)
                        .foregroundColor(.white)

                    Text("Unlock Premium Features")
                        .lexendFont(.medium, size: 14)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("TertiaryColor"))
            }

            // Features List
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "cloud.fill", text: "Unlimited cloud storage")
                FeatureRow(icon: "person.2.fill", text: "Track friends on the mountain")
            }
            .padding(.vertical, 8)

            Button(action: action) {
                HStack {
                    Text("Get Season Pass")
                        .lexendFont(.bold, size: 16)
                        .foregroundColor(.black)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("TertiaryColor"))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("SecondaryColor"),
                            Color("SecondaryColor").opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("TertiaryColor").opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("TertiaryColor"))
                .frame(width: 20)

            Text(text)
                .lexendFont(.medium, size: 14)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    VStack {
        BuySeasonPassCard(action: {
            print("Season Pass tapped")
        })
        .padding()
    }
    .appBackground()
}

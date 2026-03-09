//
//  CustomImage.swift
//  snow-buddy
//
//  Created by Claude Code
//

import SwiftUI

struct CustomImage: View {
    let imageName: String
    var maxWidth: CGFloat = 200

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
    }
}

struct MascotImage: View {
    var mascotImage: MascotImageSource = .mascotImage1
    var maxWidth: CGFloat = 200

    var body: some View {
        Image(mascotImage.rawValue)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
    }
}

enum MascotImageSource: String {
    case mascotImage1 = "MascotImage1"
    case mascotImage2 = "MascotImage2"
    case mascotImage3 = "MascotImage3"
}

#Preview {
    VStack(spacing: 20) {
        Text("Custom Image - Default Size (200)")
            .lexendFont(.bold, size: 16)

        CustomImage(imageName: "MascotImage2")

        Divider()

        Text("Mascot Image - Default (200)")
            .lexendFont(.bold, size: 16)

        MascotImage()

        Divider()

        Text("Mascot Image - Custom Size (150)")
            .lexendFont(.bold, size: 16)

        MascotImage(mascotImage: .mascotImage3, maxWidth: 150)
    }
    .padding()
    .appBackground()
}

//
//  SplashScreen.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 12/10/2025.
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                Image("LogoWithText")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }.appBackground()
    }
}

#Preview {
    SplashScreen()
}

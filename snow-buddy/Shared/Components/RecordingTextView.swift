//
//  RecordingTextView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import SwiftUI

struct RecordingIndicator: View {
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            Text("Recording in Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.red)
        }
        .onAppear {
            isPulsing = true
        }
    }
}
#Preview {
    RecordingIndicator()
}

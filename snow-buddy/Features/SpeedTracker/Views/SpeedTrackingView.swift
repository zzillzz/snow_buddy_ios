//
//  SpeedTrackingView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 26/9/2025.
//

import SwiftUI

struct SpeedTrackingView: View {
    @StateObject var trackingManager: TrackingManager
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                if trackingManager.isRecording {
                    RecordingIndicator()
                }
            }
            
            StatCard(
                title: "Total Distance",
                value: "\(Int(trackingManager.totalDistance * 0.001)) km",
                valueFont: .lexend(.bold, size: 60),
                height: 150
            )
            .frame(maxWidth: 320)
            
            HStack {
                StatCard(
                    title: "Average Speed",
                    value: "\(Int(trackingManager.averageSpeed * 3.6)) km/h",
                )

                StatCard(
                    title: "Max Speed",
                    value: "\(Int(trackingManager.topSpeed * 3.6)) km/h")
            }

            if trackingManager.isRecording {
                SecondaryActionButton(
                    title: "Stop Recording",
                    icon: "stop.circle.fill"
                ) {
                    trackingManager.stopRecording()
                }
            } else {
                PrimaryActionButton(
                    title: "Start Recording",
                    icon: "play.circle.fill"
                ) {
                    trackingManager.startRecording()
                }
            }
        }
    }
}

#Preview {
    let trackingManager = TrackingManager()
    SpeedTrackingView(trackingManager: trackingManager)
}

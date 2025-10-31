//
//  SpeedTrackingView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 26/9/2025.
//

import SwiftUI

struct SpeedTrackingView: View {
    @StateObject var trackingManager: TrackingManager
    @State var showDevInfo: Bool = false
    
    var dayStats: DayStats {
        DayStats(runs: trackingManager.completedRuns)
    }
    
    var body: some View {
        NavigationView {
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
                
                CustomButton(
                    title: trackingManager.isRecording ? "Stop Recording" : "Start Recording",
                    action: {
                        if trackingManager.isRecording {
                            trackingManager.stopRecording()
                        } else {
                            trackingManager.startRecording()
                        }
                    },
                    isActive: trackingManager.isRecording
                    
                )
                
                Button(action: { trackingManager.simulateRun()}) {
                    Text("Simulate Run")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .frame(maxWidth: .infinity, maxHeight: 10)
                }
                
                Button(action: { showDevInfo.toggle() }) {
                    VStack {
                        Text("SHOW DEV INFO")
                            .lexendFont(size: 20)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("Primary").opacity(0.2))
                    )
                }
                
                if trackingManager.isRecording && showDevInfo {
                    Text("Current Speed: \(Int(trackingManager.currentSpeed * 3.6)) km/h")
                        .font(.headline)
                    
                    Text("Elevation: \(Int(trackingManager.currentElevation))m")
                        .font(.subheadline)
                    
                    if trackingManager.currentRun != nil {
                        Text("🔴 In Run")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    } else {
                        Text("⚫ Between Runs")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .appBackground()
        }
    }
}

#Preview {
    var trackingManager = TrackingManager()
    SpeedTrackingView(trackingManager: trackingManager)
}

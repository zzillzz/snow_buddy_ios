//
//  RunCardView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//
import Foundation
import SwiftUI

struct RunCardView: View {
    let run: Run
    let isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.skiing.downhill")
                        .foregroundColor(Color("PrimaryColor"))
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Run \(run.id.uuidString.prefix(4))") // Short ID
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.primary)
                    Text("Top Speed: \(Int(run.topSpeedKmh)) km/h · Avg Speed: \(Int(run.averageSpeedKmh)) km/h")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .foregroundColor(Color.secondary)
                    .animation(.easeInOut, value: isExpanded)
            }
            .padding()
            
            if isExpanded {
                Divider()
                    .background(Color.secondary.opacity(0.3))
                
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Max Vertical Drop")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                            Text("\(Int(run.verticalDescent)) m")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.primary)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Distance")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                            Text(String(format: "%.2f km", distanceInKm()))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.primary)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Duration")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                            Text(durationString())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.primary)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Time of Day")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                            Text(timeString())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.primary)
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .animation(.easeInOut, value: isExpanded)
    }
    
    private func distanceInKm() -> Double {
        let horizontalDistance = hypot(run.endElevation - run.startElevation, run.averageSpeed * run.duration)
        return horizontalDistance / 1000.0
    }
    
    private func durationString() -> String {
        let totalSeconds = Int(run.duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: run.startTime)
    }
}


#Preview {
    RunCardView(run: mockRun, isExpanded: true)
}

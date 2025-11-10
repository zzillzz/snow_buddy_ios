//
//  RunDetailsSheetInfoView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/11/2025.
//

import Charts
import SwiftUI

struct RunDetailSheetInfo: View {
    let run: Run
    let runDetailsViewModel = RunDetailInfoViewModel()
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Heading Grid
            HStack {
                VStack(alignment: .leading) {
                    Text(run.startTime.formatted(date: .abbreviated, time: .shortened))
                        .lexendFont(size: 19)
                        .foregroundColor(.secondary)
                    
                }
                Spacer()
            }
            
            Divider()
            
            // MARK: - Stats Grid
            Grid(alignment: .leading, horizontalSpacing: 40, verticalSpacing: 16) {
                GridRow {
                    RunStatItem(
                        icon: "map.fill",
                        title: "Distance",
                        value: String(format: "%.3f km", run.distanceInKm)
                    )
                    Spacer()
                    RunStatItem(
                        icon: "clock.fill",
                        title: "Duration",
                        value: run.duration.formattedTime()
                    )
                }
                
                GridRow {
                    RunStatItem(
                        icon: "speedometer",
                        title: "Avg Speed",
                        value: String(format: "%.1f km/h", run.averageSpeedKmh)
                    )
                    Spacer()
                    RunStatItem(
                        icon: "arrow.down.right.circle.fill",
                        title: "Elev. Drop",
                        value: String(format: "%.0f m", run.verticalDescent)
                    )
                }
                
                GridRow {
                    RunStatItem(
                        icon: "flame.fill",
                        title: "Max Speed",
                        value: String(format: "%.1f km/h", run.topSpeedKmh)
                    ).foregroundStyle(.red)
                    Spacer()

                    RunStatItem(
                        icon: "arrow.down.right.circle.fill",
                        title: "Avg Slope",
                        value: "\(String(format: "%.1f", run.averageSlope))%"
                    )
                }
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
            
            Divider()

            VStack {
                RunSpeedChart(speeds: run.computeSpeeds())
                RunElevationChart(routePoints: run.routePoints)
            }

        }
        .padding()
        .lexendFont(size: 20)
    }
}

struct RunStatItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color("PrimaryColor"))
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.secondary)
                    .lexendFont(size: 16)
                
                Text(value)
                    .fontWeight(.medium)
                    .lexendFont(size: 20)
            }
        }
    }
}


#Preview {
    RunDetailSheetInfo(run: mockRun2)
}

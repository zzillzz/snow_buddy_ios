//
//  ShareableRunView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 8/11/2025.
//
import SwiftUI
import UIKit
import LinkPresentation

struct ShareableRunView: View {
    var run: Run
    var textColor: Color = .white
    var backgroundColor: Color = Color(.systemBackground)

    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Snow Buddy")
                        .lexendFont(.bold, size: 24)
                        .foregroundColor(.primary)

                    Text(run.startTime.formatted(date: .abbreviated, time: .shortened))
                        .lexendFont(.regular, size: 16)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // MARK: - Stats Grid
                Grid(horizontalSpacing: 20, verticalSpacing: 15) {
                    GridRow {
                        RunStatItem(
                            icon: "map.fill",
                            title: "Distance",
                            value: String(format: "%.3f km", run.runDistanceKm)
                        )
                        .foregroundStyle(textColor)

                        RunStatItem(
                            icon: "clock.fill",
                            title: "Duration",
                            value: run.duration.formattedTime()
                        ).foregroundStyle(textColor)
                    }

                    GridRow {
                        RunStatItem(
                            icon: "speedometer",
                            title: "Avg Speed",
                            value: String(format: "%.1f km/h", run.averageSpeedKmh)
                        ).foregroundStyle(textColor)
                        RunStatItem(
                            icon: "arrow.down.right.circle.fill",
                            title: "Elev. Drop",
                            value: String(format: "%.0f m", run.verticalDescent)
                        ).foregroundStyle(textColor)
                    }

                    GridRow {
                        RunStatItem(
                            icon: "flame.fill",
                            title: "Max Speed",
                            value: String(format: "%.1f km/h", run.topSpeedKmh)
                        ).foregroundStyle(.red)
                        RunStatItem(
                            icon: "arrow.down.right.circle.fill",
                            title: "Avg Slope",
                            value: "\(String(format: "%.1f", run.averageSlope))%"
                        ).foregroundStyle(textColor)
                    }
                }
                .padding()


                // Footer
                VStack(spacing: 4) {
                    Text("Track your runs with")
                        .lexendFont(.regular, size: 14)
                        .foregroundColor(.secondary)
                    Text("SnowBuddy")
                        .lexendFont(.bold, size: 20)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
        .frame(width: 400, height: 600)
    }
}



#Preview {
    ShareableRunView(run: mockRun1)
}

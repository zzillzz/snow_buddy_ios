//
//  ShareableRunView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 8/11/2025.
//
import SwiftUI

struct ShareableRunView: View {
    var run: Run
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(run.startTime.formatted(date: .abbreviated, time: .shortened))
                        .lexendFont(size: 19)
                        .foregroundColor(.secondary)
                }
            }.padding()
                        
            // MARK: - Stats Grid
            Grid(horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    RunStatItem(
                        icon: "map.fill",
                        title: "Distance",
                        value: String(format: "%.3f km", run.distanceInKm)
                    )
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
                    RunStatItem(
                        icon: "arrow.down.right.circle.fill",
                        title: "Avg Slope",
                        value: "\(String(format: "%.1f", run.averageSlope))%"
                    )
                }
            }
            
            VStack() {
                Text("By SnowBuddy")
                    .lexendFont(size: 19)
                    .foregroundColor(.secondary)
            }.padding(.top, 20)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


#Preview {
    ShareableRunView(run: mockRun1)
}

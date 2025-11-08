//
//  RunsDetailsSheet.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 7/11/2025.
//

import SwiftUI
import Foundation

struct RunDetailSheet: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map takes up top 60% of screen
                ScrollView {
                RunDetailMapView(run: run)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                
                // Stats section below map
                RunDetailSheetInfo(run: run)
                }
            }
            .navigationTitle("Run Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        captureShareableView(run: run)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    private func captureShareableView(run: Run) {
        let view = ShareableRunView(run: run)
        let controller = UIHostingController(rootView: view)
        
        // Instagram Stories optimal size: 1080x1920 (9:16 aspect ratio)
        let targetSize = CGSize(width: 1080, height: 1920)
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        controller.view.backgroundColor = .clear
        
        // PNG format with transparency
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false  // Critical for transparency
        format.scale = 3.0     // High resolution for retina displays
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let image = renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        
        // Convert to PNG to preserve alpha channel
        if let pngData = image.pngData(),
           let pngImage = UIImage(data: pngData) {
            shareImage = pngImage
        } else {
            shareImage = image
        }
        
        showShareSheet = true
    }
}

import Charts
struct RunDetailSheetInfo: View {
    let run: Run
    let runDetailsViewModel = RunDetailInfoViewModel()
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Heading Grid
            HStack {
                VStack(alignment: .leading) {
                    Text("Unnamed Run")
                        .lexendFont(.bold, size: 20)
                    
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


#Preview {
    RunDetailSheet(run: mockRun1)
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

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
    var body: some View {
        ZStack {
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
                            value: String(format: "%.3f km", run.runDistanceKm)
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
        }.background(Color.clear)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Enable preview for the share sheet
        controller.completionWithItemsHandler = { _, _, _, _ in }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Custom Activity Item Source for Preview
class ShareActivityItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let text: String
    
    init(image: UIImage, text: String = "") {
        self.image = image
        self.text = text
        super.init()
    }
    
    // What to actually share
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    // The actual item to share
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    // This provides the preview thumbnail
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "My Run Stats"
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}

#Preview {
    ShareableRunView(run: mockRun1)
}

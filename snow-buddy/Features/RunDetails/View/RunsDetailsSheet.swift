//
//  RunsDetailsSheet.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 7/11/2025.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct ShareableRunImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareableImage in
            guard let data = shareableImage.image.pngData() else {
                throw ShareableRunImageError.conversionFailed
            }
            return data
        }
    }

    enum ShareableRunImageError: Error {
        case conversionFailed
    }
}

struct RunDetailSheet: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: ShareableRunImage?
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
                    if let shareImage = shareImage {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview(
                                "My Snow Buddy Run",
                                image: Image(uiImage: shareImage.image)
                            )
                        ) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button("Export") {
                            captureShareableView(run: run)
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Print Stats") {
                        printRunStats(run: run)
                    }
                }
            }
            .onAppear{
                captureShareableView(run: run)
            }
        }
    }

    @MainActor
    private func captureShareableView(run: Run) {
        let view = ShareableRunView(run: run)

        // Use ImageRenderer for proper SwiftUI rendering
        let renderer = ImageRenderer(content: view)

        // Set scale for high resolution
        renderer.scale = 3.0

        // Set opaque background for better compatibility with Instagram
        renderer.isOpaque = true

        // Render to UIImage
        guard let uiImage = renderer.uiImage else { return }

        shareImage = ShareableRunImage(image: uiImage)
    }
}



#Preview {
    RunDetailSheet(run: mockRun4)
}

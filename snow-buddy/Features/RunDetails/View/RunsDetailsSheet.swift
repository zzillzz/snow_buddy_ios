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
                ToolbarItem(placement: .bottomBar) {
                    Button("Print Run Stats") {
                        printRunStats(run: run)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [ShareActivityItemSource(image: image, text: "Check out my run! 🎿")])
                }
            }
        }
    }
    
    @MainActor
    private func captureShareableView(run: Run) {
        let view = ShareableRunView(run: run)
        
        
        // Use ImageRenderer for proper SwiftUI rendering with transparency
        let renderer = ImageRenderer(content: view)
        
        // Set scale for high resolution
        renderer.scale = 3.0
        
        // Explicitly set transparent background
        renderer.isOpaque = false
                
        // Render to UIImage
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
    }
}



#Preview {
    RunDetailSheet(run: mockRun4)
}

//
//  MapView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//
import SwiftUI
@_spi(Experimental) import MapboxMaps

struct MapView: View {
    @StateObject var trackingManager: TrackingManager
    @State private var viewport: Viewport = .styleDefault
    @State private var showCompletedRuns = true

    private var completedRunsToShow: [(run: Run, index: Int)] {
        guard showCompletedRuns else { return [] }
        return trackingManager.completedRuns.enumerated()
            .filter { $0.element.coordinates.count > 1 }
            .map { (run: $0.element, index: $0.offset) }
    }

    var body: some View {
        ZStack {
            if let coordinate = trackingManager.userLocation {
                MapReader { proxy in
                    Map(viewport: $viewport) {
                        // User location puck
                        Puck2D(bearing: .heading)
                            .showsAccuracyRing(true)

                        // Current active route (bright blue, thicker)
                        if trackingManager.currentRouteCoordinates.count > 1 {
                            PolylineAnnotation(lineCoordinates: trackingManager.currentRouteCoordinates)
                                .lineColor(StyleColor(.systemBlue))
                                .lineWidth(5)
                        }
                    }
                    .mapStyle(.standard(lightPreset: .day))
                    .ornamentOptions(OrnamentOptions(
                        scaleBar: ScaleBarViewOptions(visibility: .hidden),
                        compass: CompassViewOptions(position: .topTrailing),
                        logo: LogoViewOptions(position: .bottomLeading)
                    ))
                    .onAppear {
                        updateCamera(to: coordinate)
                        // Add completed runs layers after a short delay to ensure map is loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let mapboxMap = proxy.map {
                                updateCompletedRunsLayers(on: mapboxMap)
                            }
                        }
                    }
                    .onChange(of: trackingManager.userLocation) { _, newLocation in
                        if let newLocation = newLocation {
                            updateCamera(to: newLocation, animated: true)
                        }
                    }
                    .onChange(of: showCompletedRuns) { _, _ in
                        if let mapboxMap = proxy.map {
                            updateCompletedRunsLayers(on: mapboxMap)
                        }
                    }
                    .onChange(of: trackingManager.completedRuns.count) { _, _ in
                        if let mapboxMap = proxy.map {
                            updateCompletedRunsLayers(on: mapboxMap)
                        }
                    }
                }

                VStack {
                    HStack {
                        Button(action: { showCompletedRuns.toggle() }) {
                            Image(systemName: showCompletedRuns ? "eye.fill" : "eye.slash.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                        Spacer()
                    }

                    Spacer()
                }

            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Fetching your location...")
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private func updateCamera(to coordinate: CLLocationCoordinate2D, animated: Bool = false) {
        let newViewport = Viewport.camera(
            center: coordinate,
            zoom: 16,
            bearing: 0,
            pitch: 0
        )

        if animated {
            withViewportAnimation(.easeInOut(duration: 0.3)) {
                viewport = newViewport
            }
        } else {
            viewport = newViewport
        }
    }

    private func updateCompletedRunsLayers(on mapboxMap: MapboxMap) {
        // Remove existing layers and sources
        for item in completedRunsToShow {
            let sourceId = "completed-run-source-\(item.run.id)"
            let layerId = "completed-run-layer-\(item.run.id)"

            try? mapboxMap.removeLayer(withId: layerId)
            try? mapboxMap.removeSource(withId: sourceId)
        }

        // Add new layers for completed runs
        for item in completedRunsToShow {
            let sourceId = "completed-run-source-\(item.run.id)"
            let layerId = "completed-run-layer-\(item.run.id)"

            // Create line coordinates
            let coordinates = item.run.coordinates.map {
                LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }

            // Create GeoJSON source
            var source = GeoJSONSource(id: sourceId)
            source.data = .geometry(.lineString(LineString(coordinates)))

            // Add source
            try? mapboxMap.addSource(source)

            // Create line layer
            var lineLayer = LineLayer(id: layerId, source: sourceId)
            lineLayer.lineColor = .constant(StyleColor(UIColor(colorForRun(at: item.index))))
            lineLayer.lineWidth = .constant(3)

            // Add layer
            try? mapboxMap.addLayer(lineLayer)
        }
    }
}

#Preview {
    MapView(trackingManager: TrackingManager())
}

//
//  RunDetailsMapView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

import SwiftUI
@_spi(Experimental) import MapboxMaps

struct RunDetailMapView: View {
    let run: Run

    @State private var viewport: Viewport
    @State private var selectedMapStyle: MapboxMapStyle = .standard

    init(run: Run) {
        self.run = run
        _viewport = State(initialValue: Self.calculateInitialViewport(for: run))
    }

    var body: some View {
        ZStack {
            Map(viewport: $viewport) {
                // The run path
                if run.coordinates.count > 1 {
                    PolylineAnnotation(id: "run-path", lineCoordinates: run.coordinates)
                        .lineColor(StyleColor(UIColor(named: "PrimaryColor") ?? .systemBlue))
                        .lineWidth(5)
                }

                // Start point marker
                if let startPoint = run.routePoints.first {
                    MapViewAnnotation(coordinate: startPoint.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 30, height: 30)
                            Image(systemName: "flag.fill")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                    .allowOverlap(true)
                }

                // End point marker
                if let endPoint = run.routePoints.last {
                    MapViewAnnotation(coordinate: endPoint.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 30, height: 30)
                            Image(systemName: "flag.checkered")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                    .allowOverlap(true)
                }

                // Top speed marker
                if let topSpeedPoint = run.topSpeedPoint {
                    MapViewAnnotation(coordinate: topSpeedPoint.coordinate) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color("TertiaryColor"))
                                    .frame(width: 36, height: 36)
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }

                            // Speed label
                            Text("\(Int(run.topSpeedKmh)) km/h")
                                .lexendFont(.bold, size: 15)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color("TertiaryColor"))
                                )
                                .shadow(radius: 2)
                        }
                    }
                    .allowOverlap(true)
                }
            }
            .mapStyle(selectedMapStyle.style)
            .ornamentOptions(OrnamentOptions(
                scaleBar: ScaleBarViewOptions(visibility: .hidden),
                compass: CompassViewOptions(position: .topTrailing),
                logo: LogoViewOptions(position: .bottomLeading)
            ))
            .ignoresSafeArea()

            // Map style picker overlay
            VStack {
                HStack {
                    MapStylePicker(selectedStyle: $selectedMapStyle)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }

    static func calculateInitialViewport(for run: Run) -> Viewport {
        guard !run.coordinates.isEmpty else {
            return .styleDefault
        }

        // Calculate bounding box for the route
        let coordinates = run.coordinates
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        // Add padding (30%)
        let latPadding = (maxLat - minLat) * 0.3
        let lonPadding = (maxLon - minLon) * 0.3

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Calculate appropriate zoom level
        let latDelta = (maxLat - minLat) + latPadding
        let lonDelta = (maxLon - minLon) + lonPadding

        // Approximate zoom level calculation (simplified)
        let maxDelta = max(latDelta, lonDelta)
        let zoom = max(1.0, 14.0 - log2(maxDelta / 0.01))

        return .camera(center: center, zoom: zoom, bearing: 0, pitch: 0)
    }
}

// Mapbox map style enum
enum MapboxMapStyle {
    case standard
    case satellite
    case outdoors

    var style: MapStyle {
        switch self {
        case .standard:
            return .standard(lightPreset: .day)
        case .satellite:
            return .satellite
        case .outdoors:
            return .outdoors
        }
    }

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .outdoors: return "Outdoors"
        }
    }

    var iconName: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe"
        case .outdoors: return "mountain.2"
        }
    }
}

// Map style picker component
struct MapStylePicker: View {
    @Binding var selectedStyle: MapboxMapStyle

    var body: some View {
        Menu {
            Button {
                selectedStyle = .standard
            } label: {
                Label("Standard", systemImage: "map")
            }

            Button {
                selectedStyle = .satellite
            } label: {
                Label("Satellite", systemImage: "globe")
            }

            Button {
                selectedStyle = .outdoors
            } label: {
                Label("Outdoors", systemImage: "mountain.2")
            }
        } label: {
            Image(systemName: "map")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

#Preview {
    RunDetailMapView(run: mockRun2)
}

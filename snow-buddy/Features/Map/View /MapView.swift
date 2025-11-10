//
//  MapView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//
import SwiftUI
import MapKit

struct MapView: View {
    @StateObject var trackingManager: TrackingManager
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showCompletedRuns = true

    var body: some View {
        ZStack {
            if let coordinate = trackingManager.userLocation {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    
                    // Current active route (bright blue, thicker)
                    if trackingManager.currentRouteCoordinates.count > 1 {
                        MapPolyline(coordinates: trackingManager.currentRouteCoordinates)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    }
                    
                    // Completed runs in this session
                    if showCompletedRuns {
                        ForEach(Array(trackingManager.completedRuns.enumerated()), id: \.element.id) { index, run in
                            MapPolyline(coordinates: run.coordinates)
                                .stroke(
                                    colorForRun(at: index),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapPitchToggle()
                    MapUserLocationButton()
                }
                .onAppear {
                    updateCamera(to: coordinate)
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
        let animation: Animation? = animated ? .easeInOut(duration: 0.3) : nil
        withAnimation(animation) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
}

#Preview {
    MapView(trackingManager: TrackingManager())
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

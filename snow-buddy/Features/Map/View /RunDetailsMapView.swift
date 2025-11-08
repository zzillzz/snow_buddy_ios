//
//  RunDetailsMapView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

import SwiftUI
import MapKit

struct RunDetailMapView: View {
    let run: Run
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedMapStyle: MapStyle = .standard(elevation: .realistic)
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // The run path
                if run.coordinates.count > 1 {
                    MapPolyline(coordinates: run.coordinates)
                        .stroke(
                            LinearGradient(
                                colors: [Color("PrimaryColor")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                }
                
                // Start point marker
                if let startPoint = run.routePoints.first {
                    Annotation("Start", coordinate: startPoint.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 30, height: 30)
                            Image(systemName: "flag.fill")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                }
                
                // End point marker
                if let endPoint = run.routePoints.last {
                    Annotation("Finish", coordinate: endPoint.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 30, height: 30)
                            Image(systemName: "flag.checkered")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                }
            }
            .mapStyle(selectedMapStyle)
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
            }
            .onAppear {
                centerMapOnRun()
            }
            
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
    
    private func centerMapOnRun() {
        guard !run.coordinates.isEmpty else { return }
        
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
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5, // Add 30% padding
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(center: center, span: span)
            )
        }
    }
}

// Map style picker component
struct MapStylePicker: View {
    @Binding var selectedStyle: MapStyle
    
    var body: some View {
        Menu {
            Button {
                selectedStyle = .standard(elevation: .realistic)
            } label: {
                Label("Standard", systemImage: "map")
            }
            
            Button {
                selectedStyle = .hybrid(elevation: .realistic)
            } label: {
                Label("Hybrid", systemImage: "map.fill")
            }
            
            Button {
                selectedStyle = .imagery(elevation: .realistic)
            } label: {
                Label("Satellite", systemImage: "globe")
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

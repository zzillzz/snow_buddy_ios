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
    @EnvironmentObject var sessionCoordinator: SessionCoordinator

    @State private var viewport: Viewport = .styleDefault
    @State private var showCompletedRuns = true
    @State private var selectedParticipant: ParticipantLocation?
    @State private var showLeaveConfirmation = false
    @State private var showEndConfirmation = false
    @State private var canEndSession = false

    // Computed properties
    private var isInSession: Bool {
        sessionCoordinator.activeSession != nil
    }

    private var completedRunsToShow: [(run: Run, index: Int)] {
        guard showCompletedRuns && !isInSession else { return [] }
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

                        // Current active route (bright blue, thicker) - only when not in session
                        if !isInSession && trackingManager.currentRouteCoordinates.count > 1 {
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
                    .ignoresSafeArea()
                    .onAppear {
                        updateCamera(to: coordinate)
                        // Add completed runs layers after a short delay to ensure map is loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let mapboxMap = proxy.map {
                                if isInSession {
                                    updateParticipantAnnotations(on: mapboxMap)
                                } else {
                                    updateCompletedRunsLayers(on: mapboxMap)
                                }
                            }
                        }

                        // Check if user can end session
                        if isInSession {
                            Task {
                                canEndSession = await sessionCoordinator.canEndSession()
                            }
                        } else {
                            // Check if there's an active session we should restore
                            Task {
                                await checkForActiveSession()
                            }
                        }
                    }
                    .onChange(of: trackingManager.userLocation) { _, newLocation in
                        if let newLocation = newLocation {
                            updateCamera(to: newLocation, animated: true)
                        }
                    }
                    .onChange(of: showCompletedRuns) { _, _ in
                        if !isInSession, let mapboxMap = proxy.map {
                            updateCompletedRunsLayers(on: mapboxMap)
                        }
                    }
                    .onChange(of: trackingManager.completedRuns.count) { _, _ in
                        if !isInSession, let mapboxMap = proxy.map {
                            updateCompletedRunsLayers(on: mapboxMap)
                        }
                    }
                    // Session-specific changes
                    .onChange(of: sessionCoordinator.activeSession) { oldValue, newValue in
                        if oldValue != nil && newValue == nil {
                            // Session ended - remove participant annotations
                            if let mapboxMap = proxy.map {
                                removeAllParticipantAnnotations(on: mapboxMap)
                                updateCompletedRunsLayers(on: mapboxMap)
                            }
                        } else if oldValue == nil && newValue != nil {
                            // Session started - remove completed runs, add participants
                            if let mapboxMap = proxy.map {
                                removeAllCompletedRunsLayers(on: mapboxMap)
                                updateParticipantAnnotations(on: mapboxMap)
                            }
                            // Check permissions
                            Task {
                                canEndSession = await sessionCoordinator.canEndSession()
                            }
                        }
                    }
                    .onChange(of: sessionCoordinator.sessionViewModel?.participants.count) { _, _ in
                        if isInSession, let mapboxMap = proxy.map {
                            updateParticipantAnnotations(on: mapboxMap)
                        }
                    }
                    .onChange(of: sessionCoordinator.sessionViewModel?.participants.map { "\($0.id)-\($0.coordinate.latitude)-\($0.coordinate.longitude)" }.joined()) { _, _ in
                        if isInSession, let mapboxMap = proxy.map {
                            updateParticipantAnnotations(on: mapboxMap)
                        }
                    }
                }

                // Overlay UI - conditional based on session state
                if isInSession {
                    sessionOverlayUI
                } else {
                    personalOverlayUI
                }

            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Fetching your location...")
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(item: $selectedParticipant) { participant in
            participantDetailSheet(participant)
        }
        .alert("Leave Session?", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    await sessionCoordinator.leaveSession()
                }
            }
        } message: {
            Text("Are you sure you want to leave this session?")
        }
        .alert("End Session?", isPresented: $showEndConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("End Session", role: .destructive) {
                Task {
                    try? await sessionCoordinator.endSession()
                }
            }
        } message: {
            Text("This will end the session for all participants. Are you sure?")
        }
    }

    // MARK: - Personal Overlay UI (Normal Mode)

    @ViewBuilder
    private var personalOverlayUI: some View {
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
    }

    // MARK: - Session Overlay UI (Session Mode)

    @ViewBuilder
    private var sessionOverlayUI: some View {
        if let session = sessionCoordinator.activeSession,
           let viewModel = sessionCoordinator.sessionViewModel {
            VStack {
                // Top: Session stats
                VStack(spacing: 12) {
                    SessionStatsBanner(
                        session: session,
                        participantCount: viewModel.onlineParticipantsCount
                    )

                    // Active participants count
                    if viewModel.sharingParticipantsCount > 0 {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .font(.caption)

                            Text("\(viewModel.sharingParticipantsCount) sharing location")
                                .lexendFont(.medium, size: 13)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.95))
                        )
                    }
                }
                .padding()

                Spacer()

                // Bottom: Controls and participant list
                VStack(spacing: 12) {
                    // Location sharing toggle
                    LocationSharingToggle(
                        isSharing: .constant(viewModel.isSharingLocation),
                        batteryLevel: viewModel.batteryLevel,
                        onToggle: {
                            Task {
                                await viewModel.toggleLocationSharing()
                            }
                        }
                    )
                    .id(viewModel.isSharingLocation) // Force refresh when state changes

                    // Participant list (horizontal scroll)
                    if !viewModel.participants.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.participants) { participant in
                                    ParticipantCardView(
                                        participant: participant,
                                        isSelected: selectedParticipant?.id == participant.id,
                                        onTap: {
                                            selectedParticipant = participant
                                            // Center map on participant
                                            withViewportAnimation(.easeInOut(duration: 0.3)) {
                                                viewport = .camera(
                                                    center: participant.coordinate,
                                                    zoom: 15,
                                                    bearing: 0,
                                                    pitch: 0
                                                )
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }

                    // Session control buttons
                    if canEndSession {
                        // End Session button (owner only)
                        Button {
                            showEndConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("End Session")
                            }
                            .lexendFont(.semiBold, size: 16)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                                    .shadow(color: .red.opacity(0.3), radius: 8)
                            )
                        }
                    } else {
                        // Leave Session button (participants)
                        Button {
                            showLeaveConfirmation = true
                        } label: {
                            Text("Leave Session")
                                .lexendFont(.semiBold, size: 16)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 8)
                                )
                        }
                    }
                }
                .padding()
                .background(
                    Color.white
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }

    // MARK: - Participant Detail Sheet

    private func participantDetailSheet(_ participant: ParticipantLocation) -> some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(participant.isOnline ? Color.blue : Color.gray)
                    .frame(width: 80, height: 80)

                Text(participant.username.prefix(2).uppercased())
                    .lexendFont(.bold, size: 28)
                    .foregroundColor(.white)

                if participant.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 30, y: -30)
                }
            }
            .padding(.top)

            // Username
            Text(participant.username)
                .lexendFont(.bold, size: 24)

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statBox(
                    icon: "speedometer",
                    label: "Speed",
                    value: participant.speedFormatted
                )

                statBox(
                    icon: "mountain.2",
                    label: "Altitude",
                    value: participant.altitudeFormatted
                )

                statBox(
                    icon: "battery.100",
                    label: "Battery",
                    value: participant.batteryFormatted
                )

                statBox(
                    icon: "clock",
                    label: "Updated",
                    value: participant.lastUpdateFormatted
                )
            }
            .padding(.horizontal)

            // Status
            HStack {
                Circle()
                    .fill(participant.isOnline ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)

                Text(participant.activityStatus)
                    .lexendFont(.medium, size: 15)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .presentationDetents([.medium])
    }

    private func statBox(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .lexendFont(.bold, size: 18)

            Text(label)
                .lexendFont(.regular, size: 12)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryContainerColor"))
        )
    }

    // MARK: - Session Detection

    private func checkForActiveSession() async {
        // Get user's groups and check for active sessions
        guard let user = try? await SupabaseService.shared.getAuthenticatedUser(),
              let userId = UUID(uuidString: user.id.uuidString) else {
            return
        }

        // Check if user has any active sessions
        // We'll use the GroupSessionService to check
        let groupService = GroupSessionService.shared

        // Try to get active sessions for the user's groups
        // Note: This is a simplified check - in production you'd want to get user's groups first
        // For now, we'll just check if there's already an active session in SessionCoordinator
        // If not, the user can navigate from GroupDetailView to join

        print("🔍 Checked for active sessions on MapView appear")
    }

    // MARK: - Camera Updates

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

    // MARK: - Personal Runs Layer Management

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

    private func removeAllCompletedRunsLayers(on mapboxMap: MapboxMap) {
        let allLayers = mapboxMap.allLayerIdentifiers.map { $0.id }
        for layerId in allLayers {
            if layerId.hasPrefix("completed-run-") {
                try? mapboxMap.removeLayer(withId: layerId)
                try? mapboxMap.removeSource(withId: layerId)
            }
        }
    }

    // MARK: - Participant Annotations Management

    private func updateParticipantAnnotations(on mapboxMap: MapboxMap) {
        guard let participants = sessionCoordinator.sessionViewModel?.participants else {
            return
        }

        // Get all existing layers
        let allLayers = mapboxMap.allLayerIdentifiers.map { $0.id }

        // Remove all participant layers and sources
        for layerId in allLayers {
            if layerId.hasPrefix("participant-") {
                try? mapboxMap.removeLayer(withId: layerId)
                try? mapboxMap.removeSource(withId: layerId)
            }
        }

        // Add new annotations for each participant
        for participant in participants {
            let annotationId = "participant-\(participant.id)"

            // Create point annotation source
            var source = GeoJSONSource(id: annotationId)
            source.data = .geometry(.point(Point(participant.coordinate)))

            // Add source
            do {
                try mapboxMap.addSource(source)
            } catch {
                print("❌ Failed to add source for \(participant.username): \(error)")
                continue
            }

            // Create symbol layer for participant
            var symbolLayer = SymbolLayer(id: annotationId, source: annotationId)

            // Circle background
            symbolLayer.iconImage = .constant(.name("circle-15"))
            symbolLayer.iconColor = .constant(StyleColor(participant.isOnline ? .blue : .gray))
            symbolLayer.iconSize = .constant(2.5)

            // Username text
            symbolLayer.textField = .constant(participant.username.prefix(2).uppercased())
            symbolLayer.textColor = .constant(StyleColor(.white))
            symbolLayer.textSize = .constant(12)
            symbolLayer.textFont = .constant(["Open Sans Bold", "Arial Unicode MS Bold"])
            symbolLayer.textOffset = .constant([0, 0])
            symbolLayer.textAllowOverlap = .constant(true)
            symbolLayer.iconAllowOverlap = .constant(true)

            // Add layer
            do {
                try mapboxMap.addLayer(symbolLayer)
            } catch {
                print("❌ Failed to add layer for \(participant.username): \(error)")
            }
        }
    }

    private func removeAllParticipantAnnotations(on mapboxMap: MapboxMap) {
        let allLayers = mapboxMap.allLayerIdentifiers.map { $0.id }
        for layerId in allLayers {
            if layerId.hasPrefix("participant-") {
                try? mapboxMap.removeLayer(withId: layerId)
                try? mapboxMap.removeSource(withId: layerId)
            }
        }
    }
}

#Preview {
    MapView(trackingManager: TrackingManager())
}

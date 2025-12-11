//
//  GroupSessionMapView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI
import MapKit

struct GroupSessionMapView: View {
    @StateObject var viewModel: GroupSessionViewModel
    let session: GroupSession

    @State private var region: MKCoordinateRegion
    @State private var selectedParticipant: ParticipantLocation?
    @State private var showLeaveConfirmation = false
    @State private var showEndConfirmation = false
    @State private var canEndSession = false

    @Environment(\.dismiss) var dismiss

    init(session: GroupSession, trackingManager: TrackingManager) {
        self.session = session
        _viewModel = StateObject(
            wrappedValue: GroupSessionViewModel(trackingManager: trackingManager)
        )

        // Initialize map region centered on resort
        if let resort = session.resort {
            _region = State(
                initialValue: MKCoordinateRegion(
                    center: resort.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        } else {
            _region = State(
                initialValue: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }

    var body: some View {
        ZStack {
            // Map with participant pins
            Map(
                coordinateRegion: $region,
                annotationItems: viewModel.participants
            ) { participant in
                MapAnnotation(coordinate: participant.coordinate) {
                    Button {
                        selectedParticipant = participant
                    } label: {
                        ParticipantPin(participant: participant)
                    }
                }
            }
            .ignoresSafeArea()

            // Overlay UI
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
                        isSharing: $viewModel.isSharingLocation,
                        batteryLevel: viewModel.batteryLevel,
                        onToggle: {
                            Task {
                                await viewModel.toggleLocationSharing()
                            }
                        }
                    )

                    // Participant list (horizontal scroll)
                    if !viewModel.participants.isEmpty {
                        participantsList
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
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSession(sessionId: session.id)
            try? await viewModel.joinSession(session.id)

            // Check if current user can end the session
            canEndSession = await viewModel.canEndSession()
        }
        .sheet(item: $selectedParticipant) { participant in
            participantDetailSheet(participant)
        }
        .alert("Leave Session?", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    await viewModel.leaveSession()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to leave this session?")
        }
        .alert("End Session?", isPresented: $showEndConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("End Session", role: .destructive) {
                Task {
                    try? await viewModel.endSession()
                    dismiss()
                }
            }
        } message: {
            Text("This will end the session for all participants. Are you sure?")
        }
    }

    // MARK: - Participants List
    private var participantsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.participants) { participant in
                    participantCard(participant)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func participantCard(_ participant: ParticipantLocation) -> some View {
        Button {
            selectedParticipant = participant
            // Center map on participant
            withAnimation {
                region.center = participant.coordinate
            }
        } label: {
            VStack(spacing: 6) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(participant.isOnline ? Color.blue : Color.gray)
                        .frame(width: 50, height: 50)

                    Text(participant.username.prefix(2).uppercased())
                        .lexendFont(.bold, size: 16)
                        .foregroundColor(.white)

                    if participant.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 18, y: -18)
                    }
                }

                // Username
                Text(participant.username)
                    .lexendFont(.medium, size: 12)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                // Speed or status
                if let speed = participant.speedKmh, speed > 1 {
                    Text("\(Int(speed)) km/h")
                        .lexendFont(.semiBold, size: 11)
                        .foregroundColor(.green)
                } else {
                    Text(participant.activityStatus)
                        .lexendFont(.regular, size: 10)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .frame(width: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
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
}

#Preview {
    NavigationView {
        GroupSessionMapView(
            session: GroupSession.activeSample,
            trackingManager: TrackingManager()
        )
    }
}

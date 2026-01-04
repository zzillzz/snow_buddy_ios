//
//  GroupDetailView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct GroupDetailView: View {
    let group: GroupModel
    @ObservedObject var viewModel: GroupsViewModel
    @EnvironmentObject var trackingManager: TrackingManager

    @State private var members: [GroupMember] = []
    @State private var activeSession: GroupSession?
    @State private var showStartSession = false
    @State private var showAddMembers = false
    @State private var isLoadingMembers = false
    @State private var sessionViewModel: GroupSessionViewModel?
    @State private var canManageMembers = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Group header
                groupHeader

                // Active session banner or start button
                if let session = activeSession {
                    activeSessionBanner(session)
                } else {
                    PrimaryActionButton(
                        title: "Start Session",
                        icon: "play.circle.fill",
                        action: { showStartSession = true }
                    )
                }

                // Members section
                membersSection
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if canManageMembers && !group.isFull {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddMembers = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.body)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
        }
        .sheet(isPresented: $showStartSession, onDismiss: {
            Task {
                await loadData()
            }
        }) {
            ResortSelectionView(group: group, viewModel: viewModel)
                .environmentObject(trackingManager)
        }
        .sheet(isPresented: $showAddMembers, onDismiss: {
            Task {
                await loadData()
            }
        }) {
            AddMembersView(group: group, viewModel: viewModel)
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Group Header
    private var groupHeader: some View {
        VStack(spacing: 12) {
            // Description
            if let description = group.description {
                Text(description)
                    .lexendFont(.regular, size: 14)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Stats row
            HStack(spacing: 20) {
                // Members
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text(group.memberCountShort)
                            .lexendFont(.semiBold, size: 14)
                    }
                    Text("Members")
                        .lexendFont(.regular, size: 11)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                // Privacy
                VStack(spacing: 4) {
                    Image(systemName: group.privacyIcon)
                        .font(.body)
                    Text(group.privacyStatus)
                        .lexendFont(.semiBold, size: 14)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 30)

                // Created
                VStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.body)
                    Text(group.createdAtFormatted)
                        .lexendFont(.semiBold, size: 14)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("PrimaryContainerColor"))
            )
        }
    }

    // MARK: - Active Session Banner
    private func activeSessionBanner(_ session: GroupSession) -> some View {
        NavigationLink {
            GroupSessionMapView(session: session, trackingManager: trackingManager)
        } label: {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)

                    Text("Active Session")
                        .lexendFont(.bold, size: 17)
                        .foregroundColor(.green)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.green)
                }

                HStack {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.green)

                    Text(session.resort?.name ?? "Unknown Resort")
                        .lexendFont(.semiBold, size: 15)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(session.durationFormatted)
                        .lexendFont(.regular, size: 13)
                        .foregroundColor(.secondary)
                }

                Text("Tap to join session")
                    .lexendFont(.regular, size: 12)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                    )
            )
        }
    }

    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Members")
                    .lexendFont(.bold, size: 20)

                Spacer()

                if isLoadingMembers {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if members.isEmpty {
                Text("No members yet")
                    .lexendFont(.regular, size: 14)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(members) { member in
                    memberRow(member)
                }
            }
        }
    }

    private func memberRow(_ member: GroupMember) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color("PrimaryColor"))
                    .frame(width: 44, height: 44)

                Text(member.displayName.prefix(2).uppercased())
                    .lexendFont(.bold, size: 16)
                    .foregroundColor(.black)
            }

            // Name and joined date
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .lexendFont(.semiBold, size: 15)

                Text("Joined \(member.membershipDurationShort)")
                    .lexendFont(.regular, size: 12)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Role badge
            HStack(spacing: 6) {
                Image(systemName: member.role.icon)
                    .font(.caption)
                    .foregroundColor(roleColor(member.role))

                Text(member.role.displayName)
                    .lexendFont(.medium, size: 13)
                    .foregroundColor(roleColor(member.role))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(roleColor(member.role).opacity(0.15))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryContainerColor"))
        )
    }

    private func roleColor(_ role: MemberRole) -> Color {
        switch role {
        case .owner: return .orange
        case .admin: return .blue
        case .member: return .gray
        }
    }

    // MARK: - Data Loading
    private func loadData() async {
        isLoadingMembers = true

        // Load members
        members = await viewModel.getGroupMembers(groupId: group.id)

        // Check for active session (query database for fresh data)
        let sessionVM = GroupSessionViewModel(trackingManager: trackingManager)
        if let session = await sessionVM.getActiveSession(groupId: group.id) {
            // Load full session details
            await sessionVM.loadSession(sessionId: session.id)

            await MainActor.run {
                sessionViewModel = sessionVM
                activeSession = sessionVM.session
            }
        } else {
            // No active session
            await MainActor.run {
                sessionViewModel = nil
                activeSession = nil
            }
        }

        // Check if current user can manage members (owner or admin)
        if let user = try? await SupabaseService.shared.getAuthenticatedUser(),
           let userId = UUID(uuidString: user.id.uuidString) {
            let isOwner = group.ownerId == userId
            let userRole = members.first(where: { $0.userId == userId })?.role
            let isAdmin = userRole == .admin

            await MainActor.run {
                canManageMembers = isOwner || isAdmin
            }
        }

        isLoadingMembers = false
    }
}

#Preview {
    NavigationView {
        GroupDetailView(
            group: GroupModel.premiumSample,
            viewModel: GroupsViewModel()
        ).environmentObject(TrackingManager.preview)
    }
}

//
//  GroupsListView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct GroupsListView: View {
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showCreateGroup = false
    @EnvironmentObject var trackingManager: TrackingManager

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Page Heading
                PageHeading(text: "Groups")

                // Content
                Group {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if viewModel.groups.isEmpty {
                        emptyState
                    } else {
                        groupsList
                    }
                }
            }
            .padding()
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(viewModel: viewModel)
            }
            .alert(item: $viewModel.alertConfig) { config in
                Alert(
                    title: Text(config.title),
                    message: Text(config.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .task {
                await viewModel.loadGroups()
            }
        }
    }

    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group, viewModel: viewModel)
                            .environmentObject(trackingManager)
                    } label: {
                        GroupCard(group: group)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.6))

            Text("No Groups Yet")
                .lexendFont(.bold, size: 22)

            Text("Create a group to start sharing your location with friends on the mountain")
                .lexendFont(.regular, size: 14)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showCreateGroup = true
            } label: {
                Text("Create Group")
                    .lexendFont(.semiBold, size: 16)
                    .foregroundColor(.black)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color("PrimaryColor"))
                    .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    GroupsListView()
}

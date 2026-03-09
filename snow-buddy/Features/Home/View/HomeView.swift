//
//  HomeView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 20/9/2025.
//

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var sessionCoordinator: SessionCoordinator

    @State var username = "User"
    @State private var selectedTab: Int = 2
    @State private var trackingManager: TrackingManager

    @Environment(\.modelContext) private var modelContext

    init() {
        let tm = TrackingManager()
        _trackingManager = State(wrappedValue: tm)
        _sessionCoordinator = StateObject(
            wrappedValue: SessionCoordinator(trackingManager: tm)
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            RunListView()
                .tabItem {
                    Label("History", systemImage: "plus")
                }
                .tag(0)


            GroupsListView()
                .environmentObject(trackingManager)
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(1)

            DashboardView()
                .environmentObject(trackingManager)
                .tabItem{
                    Text("Record")
                    Image("RunTabImage")
                }
                .tag(2)


            MapView(trackingManager: trackingManager)
                .tabItem{
                    Label("Map", systemImage: "map")
                }
                .tag(3)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackgroundVisibility(.visible, for: .tabBar)

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(4)
        }
        .environmentObject(sessionCoordinator)
        .appBackground()
        .tint(Color("PrimaryColor"))
        .onAppear {
            trackingManager.setModelContext(modelContext)
        }
        .onChange(of: sessionCoordinator.shouldNavigateToMap) { _, shouldNavigate in
            if shouldNavigate {
                print("🗺️ Auto-navigating to Map tab")
                selectedTab = 3 // Map tab
                sessionCoordinator.shouldNavigateToMap = false
            }
        }
    }


}

#Preview {
    HomeView()
}

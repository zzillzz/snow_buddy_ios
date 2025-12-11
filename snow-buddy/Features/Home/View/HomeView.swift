//
//  HomeView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 20/9/2025.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    @State var username = "User"
    @State private var selectedTab: Int = 2
    @State private var trackingManager: TrackingManager = TrackingManager()
    
    @Environment(\.modelContext) private var modelContext
    
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
            
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(4)

            SettingsView()
                .environmentObject(trackingManager)
                .tabItem {
                    Label("Setting", systemImage: "gear")
                }
                .tag(5)
        }
        .appBackground()
        .tint(Color("PrimaryColor"))
        .onAppear {
            trackingManager.setModelContext(modelContext)
        }
    }
    
    
}

#Preview {
    HomeView()
}

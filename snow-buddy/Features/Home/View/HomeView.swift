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
    @State private var selectedTab: Int = 1
    @State private var trackingManager: TrackingManager = TrackingManager()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RunListView()
                .tabItem {
                    Label("Runs", systemImage: "plus")
                }
                .tag(0)
            DashboardView()
                .environmentObject(trackingManager)
                .tabItem{
                    Text("Record")
                    Image("RunTabImage")
                }
                .tag(1)
            
            MapView(trackingManager: trackingManager)
                .tabItem{
                    Label("Map", systemImage: "map")
                }
            
            SettingsView()
                .environmentObject(trackingManager)
                .tabItem {
                    Label("Setting", systemImage: "gear")
                }
                .tag(2)
        }
        .appBackground()
        .tint(Color("SecondaryColor"))
        .onAppear {
            trackingManager.setModelContext(modelContext)
        }
    }
    
    
}

#Preview {
    HomeView()
}

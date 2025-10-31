//
//  HomeView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 20/9/2025.
//

import SwiftUI

struct HomeView: View {
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor(.white)
    }
    
    @StateObject private var viewModel = HomeViewModel()
    @State var username = "User"
    @State private var selectedTab: Int = 1
    @State private var trackingManager: TrackingManager = TrackingManager()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RunListView()
                .tabItem {
                    Label("Other", systemImage: "plus")
                }
                .tag(0)
            DashboardView()
                .environmentObject(trackingManager)
                .tabItem{
                    Text("Record")
                    Image("RunTabImage")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Setting", systemImage: "gear")
                }
                .tag(2)
        }
        .appBackground()
        .tint(Color("Primary"))
        .onAppear {
            trackingManager.setModelContext(modelContext)
        }
    }
    
    
}

#Preview {
    HomeView()
}

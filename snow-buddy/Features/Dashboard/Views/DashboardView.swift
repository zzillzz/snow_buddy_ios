//
//  DashboardView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 24/9/2025.
//

import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject var trackingManager: TrackingManager
    @StateObject private var viewModel = HomeViewModel()
    @State var username = "User"
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                SpeedTrackingView(trackingManager: trackingManager)
                Spacer()
                
            }
            .appBackground()
            .task {
                await viewModel.loadUser()
                if let userName = viewModel.user?.username {
                    username = userName
                }
            }
            .navigationTitle( "Welcome \(username)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    var trackingManager = TrackingManager()
    DashboardView()
        .environmentObject(trackingManager)
        
}

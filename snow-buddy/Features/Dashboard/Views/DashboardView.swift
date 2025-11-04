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
    @State var username = "AReallylongusernamehere"
    
    var lastRun: Run? {
        trackingManager.completedRuns.last
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Welcome").lexendFont(.extraBold, size: 25)
                    Text("\(username)!").lexendFont(.extraBold, size: 25)
                }
                
                SpeedTrackingView(trackingManager: trackingManager)
                Spacer()
                if let run = lastRun {
                    VStack(spacing: 10) {
                        NavigationLink(destination: SessionRunsView(completedRuns: trackingManager.completedRuns)){
                            VStack(alignment: .leading){
                                Text("Runs Completed: \(trackingManager.completedRuns.count)")
                                    .lexendFont(.extraBold, size: 20)
                                RunCard(run: run)
                            }
                            
                        }
                    }.buttonStyle(.plain)
                }
                
            }
            .padding()
            .appBackground()
            .task {
                await viewModel.loadUser()
                if let userName = viewModel.user?.username {
                    username = userName
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(TrackingManager.preview)
}



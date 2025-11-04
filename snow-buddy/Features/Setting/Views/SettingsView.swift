//
//  SettingsView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var trackingManager: TrackingManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var showDeleteAlert = false
    @State var showDevInfo: Bool = false

    
    var body: some View {
        NavigationStack {
            
            VStack {
                CustomButton(title: "Logout Button", action: {
                    viewModel.logOutUser()
                })
                .padding(.bottom, 50)
                
                CustomButton(title: "Simulate Run", style: .tertiary, action: {
                    trackingManager.simulateRun()
                })
                .padding(.bottom, 50)
                
                DangerButton(title: "Delete All Run Data", action: {
                    showDeleteAlert = true
                    print("button pressed")
                })
                .padding(.bottom, 50)
                
                Button(action: { showDevInfo.toggle() }) {
                    VStack {
                        Text("SHOW DEV INFO")
                            .lexendFont(size: 20)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("PrimaryColor").opacity(0.2))
                    )
                }
                
                if trackingManager.isRecording && showDevInfo {
                    Text("Current Speed: \(Int(trackingManager.currentSpeed * 3.6)) km/h")
                        .font(.headline)
                    
                    Text("Elevation: \(Int(trackingManager.currentElevation))m")
                        .font(.subheadline)
                    
                    if trackingManager.currentRun != nil {
                        Text("🔴 In Run")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    } else {
                        Text("⚫ Between Runs")
                            .foregroundColor(.gray)
                    }
                }
                
            }
            .alert("Delete All Run Data?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    let runManager = RunManager(modelContext: modelContext)
                    runManager.deleteAllRuns()
                }
            }
            .padding()
            .navigationTitle("Setting")
            .appBackground()
        }
        
    }
}

class SettingsViewModel: ObservableObject {
    func resetAllRunData() {
        
    }
}

#Preview {
    let trackingManager = TrackingManager()
    SettingsView().environmentObject(trackingManager)
}

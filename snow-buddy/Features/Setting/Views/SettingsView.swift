//
//  SettingsView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            
            VStack {
                CustomButton(title: "Logout Button", action: {
                    viewModel.logOutUser()
                })
                .padding(.bottom, 50)
                
                
                DangerButton(title: "Delete All Run Data", action: {
                    showDeleteAlert = true
                    print("button pressed")
                })
                .padding(.bottom, 50)
                
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
    SettingsView()
}

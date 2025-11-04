//
//  SessionRunsView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

import SwiftUI

struct SessionRunsView: View {
    var completedRuns: [Run]
    @State private var showRunsSheet = false
    @State private var selectedRun: Run? = nil
    
    var body: some View {
        ScrollView {
            ForEach(completedRuns, id: \.id) { run in
                VStack{
                    RunCard(run: run, buttonCardColor: .tertiary, buttonCardImage: "chevron.down")
                        .padding(.bottom)
                        .onTapGesture {
                            selectedRun = run
                        }
                }
            }
        }
        .padding()
        .sheet(item: $selectedRun) { run in
            RunDetailSheet(run: run)
        }
    }
}

struct RunDetailSheet: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map takes up top 60% of screen
                RunDetailMapView(run: run)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                
                // Stats section below map
                ScrollView {
                    RunCard(run: run, buttonCardColor: .tertiary, buttonCardImage: "chevron.down")
                        .padding()
                }
            }
            .navigationTitle("Run Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SessionRunsView(completedRuns: listOfMockRuns)
}

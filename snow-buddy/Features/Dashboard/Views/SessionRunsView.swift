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

#Preview {
    SessionRunsView(completedRuns: listOfMockRuns)
}

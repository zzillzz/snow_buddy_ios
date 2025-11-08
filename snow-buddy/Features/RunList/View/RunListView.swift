//
//  RunListView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import SwiftUI
import _SwiftData_SwiftUI

struct RunListView: View {
    
    @State private var expandedRunId: UUID? = nil
    @Query(sort: \Run.startTime, order: .reverse) private var runs: [Run]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                PageHeading(text: "Runs")
                if runs.isEmpty {
                    Spacer()
                    NoRunsView()
                    Spacer()
                } else {
                    RunsView(runs: runs)
                }
            }
            .padding()
            .appBackground()
        }
    }
}

struct NoRunsView: View {
    var body: some View {
        VStack{
            Text("You dont have any runs recorded yet. Start Shredding and see all your runs here!")
                .lexendFont(.bold, size: 30)
                .multilineTextAlignment(.center)
        }
    }
}

struct RunsView: View {
    var runs: [Run]
    @State private var selectedRun: Run? = nil
    
    // Group runs by date
    private var groupedRuns: [(date: Date, runs: [Run])] {
        let calendar = Calendar.current
        
        // Group runs by calendar date
        let grouped = Dictionary(grouping: runs) { run in
            calendar.startOfDay(for: run.startTime)
        }
        
        // Sort by date (most recent first) and sort runs within each group
        return grouped.map { (date: $0.key, runs: $0.value.sorted { $0.startTime > $1.startTime }) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedRuns, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date Header
                        Text(formatDate(group.date))
                            .lexendFont(.extraBold, size: 20)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(group.runs, id:\.id) { run in
                                RunCard(
                                    run: run,
                                    buttonCardColor: .tertiary,
                                    buttonCardImage: "chevron.down"
                                )
                                .onTapGesture {
                                    selectedRun = run
                                }
                            }
                        }
                        
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedRun) { run in
            RunDetailSheet(run: run)
        }
    }
    
    // Format date with relative formatting
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Run.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    for run in sampleMockRuns {
        container.mainContext.insert(run)
    }
    
    return RunListView().modelContainer(container)
}

#Preview {
    let container = try! ModelContainer(
        for: Run.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    RunListView().modelContainer(container)
}



//
//RunCardView(run: run, isExpanded: expandedRunId == run.id)
//    .onTapGesture {
//        withAnimation(.easeInOut) {
//            if expandedRunId == run.id {
//                expandedRunId = nil
//            } else {
//                expandedRunId = run.id
//            }
//        }
//    }



// DEBUG BUTTON
//            Button("Debug: Fetch Runs") {
//                let runManager = RunManager(modelContext: modelContext)
//                let fetchedRuns = runManager.fetchAllRuns()
//                print("🐛 Fetched \(fetchedRuns.count) runs from database")
//                for run in fetchedRuns {
//                    print("🐛 Run: \(run.id), speed: \(run.topSpeed)")
//                }
//            }
//            .padding()

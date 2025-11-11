//
//  RunDayCard.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 11/11/2025.
//

import SwiftUI

struct RunDayCard: View {
    let runs: [Run]
    let date: String
    @State private var selectedRun: Run? = nil
    @State private var isExpanded = false
    
    func highestTopSpeed(from runs: [Run]) -> Double {
        runs.map { $0.topSpeed }.max() ?? 0
    }
    
    func totalDistance(in runs: [Run]) -> Double {
        guard !runs.isEmpty else { return 0 }
        return runs.reduce(0) { $0 + $1.runDistanceKm }
    }
    
    func averageSpeed(from runs: [Run]) -> Double {
        guard !runs.isEmpty else { return 0 }
        let total = runs.reduce(0) { $0 + $1.averageSpeed }
        return total / Double(runs.count)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {

                HStack {
                    Text(date)
                        .lexendFont(.bold, size: 25)
                    Spacer()
                    CardChevron(image: "chevron.down")
                }
                .padding(.bottom, 15)
                
                VStack(alignment: .leading) {
                    HStack() {
                        Text("Runs: \(runs.count)")
                            .lexendFont(size: 16)
                        Spacer()
                        Text("Top Speed: \(highestTopSpeed(from: runs), specifier: "%.1f")")
                            .lexendFont(size: 16)
                    }
                    HStack() {
                        Text("Total Distance: \(totalDistance(in: runs), specifier: "%.1f")")
                            .lexendFont(size: 16)
                        Spacer()
                        Text("Avg Speed: \(averageSpeed(from: runs), specifier: "%.1f")")
                            .lexendFont(size: 16)
                    }
                    
                }
                .padding(.trailing, 40)
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            Divider()
            
            if isExpanded {
                ForEach(runs) { run in
                    RunCardWithoutBackRound(run: run, buttonCardImage: "chevron.down")
                        .padding(.top, 20)
                        .onTapGesture {
                            selectedRun = run
                        }
                }.transition(.scale.combined(with: .opacity))
            }
            
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryColor").opacity(0.2))
        )
        .sheet(item: $selectedRun) { run in
            RunDetailSheet(run: run)
        }
    }
}

#Preview {
    var isExpanded: Bool = true
    RunDayCard(
        runs: [mockRun1, mockRun2],
        date: "12 November 2025"
    )
}

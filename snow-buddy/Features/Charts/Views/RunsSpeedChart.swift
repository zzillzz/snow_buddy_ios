//
//  RunsSpeedChart.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 8/11/2025.
//
import SwiftUI
import Charts

struct RunSpeedChart: View {
    let speeds: [(time: Date, speed: Double)]
    
    var body: some View {
        Chart(speeds, id: \.time) { data in
            LineMark(
                x: .value("Time", data.time),
                y: .value("Speed (km/h)", data.speed)
            )
            .foregroundStyle(Color("SecondaryColor"))
        }
        .frame(height: 200)
        .chartYAxisLabel("Speed (km/h)")
    }
}

#Preview {
    RunSpeedChart(speeds: mockRun1.computeSpeeds())
}

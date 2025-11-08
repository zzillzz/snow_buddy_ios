//
//  RunElevationChart.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 8/11/2025.
//

import Charts
import SwiftUI
import Foundation

struct RunElevationChart: View {
    let routePoints: [RoutePoint]
    
    // Prepare valid chart data
    var validData: [(time: Date, altitude: Double)] {
        routePoints.compactMap { point in
            guard let alt = point.altitude, let time = point.timestamp else { return nil }
            return (time, alt)
        }
    }
    
    // Compute elevation range
    private var elevationRange: ClosedRange<Double>? {
        let alts = validData.map(\.altitude)
        guard let minAlt = alts.min(), let maxAlt = alts.max(), minAlt != maxAlt else { return nil }
        return (minAlt - 5)...(maxAlt + 5)
    }
    
    var body: some View {
            // Only show chart if there’s data
            if validData.count > 1 {
                let baseChart = Chart(validData, id: \.time) { data in
                    LineMark(
                        x: .value("Time", data.time),
                        y: .value("Elevation (m)", data.altitude)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color("SecondaryColor"))
                }
                    .chartYAxisLabel("Elevation (m)")
                    .frame(height: 200)
                    .padding(.horizontal)
                
                // Conditionally apply the domain modifier
                if let range = elevationRange {
                    baseChart.chartYScale(domain: range)
                } else {
                    baseChart
                }
            } else {
                // Graceful empty state
                Text("Elevation data unavailable")
                    .foregroundColor(Color("TertiaryColor"))
                    .lexendFont(size: 15)
                    .frame(height: 200)
            }
        }
}


#Preview {
    RunElevationChart(routePoints: mockRun1.routePoints)
    RunElevationChart(routePoints: [])

}

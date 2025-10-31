//
//  DataManager.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 12/10/2025.
//
import Foundation
import SwiftData

class RunManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Save a new run
        func saveRun(startTime: Date, endTime: Date, topSpeed: Double, averageSpeed: Double, startElevation: Double, endElevation: Double, verticalDescent: Double) {
            let run = Run(
                startTime: startTime,
                endTime: endTime,
                topSpeed: topSpeed,
                averageSpeed: averageSpeed,
                startElevation: startElevation,
                endElevation: endElevation,
                verticalDescent: verticalDescent
            )
            
            modelContext.insert(run)
            
            do {
                try modelContext.save()
                print("Run saved successfully")
            } catch {
                print("Failed to save run: \(error)")
            }
        }
    
    func saveRun(_ run: Run) {
        modelContext.insert(run)
            
            do {
                try modelContext.save()
                print("Run saved successfully")
            } catch {
                print("Failed to save run: \(error)")
            }
        }
    
    // Delete a run
        func deleteRun(_ run: Run) {
            modelContext.delete(run)
            
            do {
                try modelContext.save()
                print("Run deleted successfully")
            } catch {
                print("Failed to delete run: \(error)")
            }
        }
    
    // Fetch all runs
        func fetchAllRuns() -> [Run] {
            let descriptor = FetchDescriptor<Run>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
            
            do {
                return try modelContext.fetch(descriptor)
            } catch {
                print("Failed to fetch runs: \(error)")
                return []
            }
        }
    
    // Fetch runs for a specific date
        func fetchRunsForDate(_ date: Date) -> [Run] {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = #Predicate<Run> { run in
                run.startTime >= startOfDay && run.startTime < endOfDay
            }
            
            let descriptor = FetchDescriptor<Run>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.startTime, order: .forward)]
            )
            
            do {
                return try modelContext.fetch(descriptor)
            } catch {
                print("Failed to fetch runs for date: \(error)")
                return []
            }
        }
    
    // Get stats for a specific date
        func getStatsForDate(_ date: Date) -> DayStats {
            let runs = fetchRunsForDate(date)
            return DayStats(runs: runs)
        }
    
    // Delete all runs
    func deleteAllRuns() {
        let descriptor = FetchDescriptor<Run>()
        
        do {
            let allRuns = try modelContext.fetch(descriptor)
            print("Found \(allRuns.count) found")
            for run in allRuns {
                modelContext.delete(run)
            }
            try modelContext.save()
            print("All runs deleted successfully")
        } catch {
            print("Failed to delete all runs: \(error)")
        }
    }
    
}

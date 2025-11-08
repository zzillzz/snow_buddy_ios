//
//  RunDetailsViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 7/11/2025.
//

import Foundation

class RunDetailInfoViewModel: ObservableObject {
    func dateFormater (timeInterval: TimeInterval) -> String {
        print(timeInterval)
        // Convert TimeInterval to a Date object (e.g., relative to a reference date)
        let date = Date(timeIntervalSinceReferenceDate: timeInterval)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss" // Customize your desired format

        let formattedTime = dateFormatter.string(from: date)
        return formattedTime // Output: "01:01:05"
    }
}


extension TimeInterval {
    func formattedTime() -> String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

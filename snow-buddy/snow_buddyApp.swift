//
//  snow_buddyApp.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/9/2025.
//

import SwiftUI
import SwiftData

@main
struct snow_buddyApp: App {

    init() {
        // Initialize Mapbox
        _ = MapboxService.shared
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .background(Color("Background"))
        }
        .modelContainer(for: Run.self)
        
    }
   
}

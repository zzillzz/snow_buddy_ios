//
//  LastRunCard.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//

import Foundation
import SwiftUI

struct RunCard: View {
    var run: Run
    var buttonCardColor: CustomButtonStyle = .primary
    var buttonCardImage: String = "chevron.right"
    var label: String?
    
    var body: some View {
        VStack{
            VStack(alignment: .trailing) {
                if let label = label {
                    Text(label)
                        .lexendFont(size: 15)
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Distance")
                        Text("\(Int(run.distanceInKm)) km")
                            .lexendFont(.bold, size: 20)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Average Speed")
                        Text("\(Int(run.averageSpeed * 3.6)) km/h")
                            .lexendFont(.bold, size: 20)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Max Speed")
                        Text("\(Int(run.topSpeed * 3.6)) km/h")
                            .lexendFont(.bold, size: 20)
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    ButtonCard(cardColor: buttonCardColor, image: buttonCardImage)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("PrimaryColor").opacity(0.2))
                )
            }
        }
        .lexendFont(size: 15)
    }
}

#Preview {
    let startTime = Date()
    let endTime = Date().addingTimeInterval(120)
    RunCard(
        run: Run(
            startTime: startTime,
            endTime: endTime,
            topSpeed: 15.0, // 54 km/h
            averageSpeed: 10.0, // 36 km/h
            startElevation: 2000,
            endElevation: 1900,
            verticalDescent: 100,
            routePoints: []
        ),
        label: "Last Run"
    )
}




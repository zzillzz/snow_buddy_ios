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
    
    @State private var isPressed = false
    
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
                        Text("\(Int(run.runDistanceKm)) km")
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
                    CardChevron(image: buttonCardImage)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("PrimaryColor").opacity(0.2))
                )
            }
        }
        .lexendFont(size: 15)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

struct RunCardWithoutBackRound: View {
    let run: Run
    var buttonCardColor: CustomButtonStyle = .primary
    var buttonCardImage: String = "chevron.right"
    var label: String?
    
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .trailing) {
            if let label = label {
                Text(label)
                    .lexendFont(size: 15)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("Distance")
                    Text("\(Int(run.runDistanceKm)) km")
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
                CardChevron(image: buttonCardImage)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

struct CardChevron: View {
    var color: CustomButtonStyle = .primary
    var image: String = "chevron.right"
    @Binding var shouldRotate: Bool
    
    init(color: CustomButtonStyle = .primary, image: String = "chevron.right", shouldRotate: Binding<Bool> = .constant(false)) {
        self.color = color
        self.image = image
        self._shouldRotate = shouldRotate
    }
    
    private var backgroundColor: Color {
        switch color {
        case .primary:
            return Color("PrimaryColor")
        case .secondary:
            return Color("SecondaryColor")
        case .tertiary:
            return Color("TertiaryColor")
        }
    }

    var body: some View {
        VStack {
            Image(systemName: image)
                .foregroundStyle(backgroundColor)
                .bold()
                .font(.system(size: 24))
                .rotationEffect(.degrees(shouldRotate ? 180 : 0))
        }
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
    
    CardChevron()
    RunCardWithoutBackRound(run: mockRun1)
}




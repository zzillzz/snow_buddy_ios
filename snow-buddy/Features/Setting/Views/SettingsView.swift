//
//  SettingsView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var trackingManager: TrackingManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    
    @State var useMetricUnits: Bool = true

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                PageHeading(text: "Settings")

                ScrollView {
                    UserCard(user: viewModel.user)
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading) {
                        Text("Preferences")
                            .lexendFont(.bold, size: 16)
                            .foregroundColor(.gray)
                        ListRowWithToggle(title: "Metric units", isOn: $useMetricUnits)
                    }
                    .padding(.bottom, 20)
                    
                    VStack(alignment: .leading) {
                        Text("Dev Options")
                            .lexendFont(.bold, size: 16)
                            .foregroundColor(.gray)
                        ListRow(
                            icon: "lock.fill",
                            iconColor: Color("TertiaryColor"),
                            title: "Dev Setting"
                        ) {
                            DevSettingView(trackingManager: trackingManager)
                        }
                    }.padding(.bottom, 20)
                    
                    if (viewModel.user != nil) {
                        LogoutButton {
                            viewModel.logOutUser()
                        }
                    }
                }
            }
            .padding()
            .appBackground()
        }
        .task {
            await viewModel.loadUser()
        }
    }
}

#Preview {
    let trackingManager = TrackingManager()
    SettingsView().environmentObject(trackingManager)
}


//Button(action: { showDevInfo.toggle() }) {
//    VStack {
//        Text("SHOW DEV INFO")
//            .lexendFont(size: 20)
//    }
//    .padding()
//    .background(
//        RoundedRectangle(cornerRadius: 12)
//            .fill(Color("PrimaryColor").opacity(0.2))
//    )
//}
//
//if trackingManager.isRecording && showDevInfo {
//    Text("Current Speed: \(Int(trackingManager.currentSpeed * 3.6)) km/h")
//        .font(.headline)
//    
//    Text("Elevation: \(Int(trackingManager.currentElevation))m")
//        .font(.subheadline)
//    
//    if trackingManager.currentRun != nil {
//        Text("🔴 In Run")
//            .foregroundColor(.red)
//            .fontWeight(.bold)
//    } else {
//        Text("⚫ Between Runs")
//            .foregroundColor(.gray)
//    }
//}

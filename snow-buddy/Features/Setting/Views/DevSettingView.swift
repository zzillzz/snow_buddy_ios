//
//  DevSettingView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/11/2025.
//

import SwiftUI

struct DevSettingView: View {
    @ObservedObject var trackingManager: TrackingManager
    @Environment(\.modelContext) private var modelContext

    @State var showDeleteAlert = false
    @State var showDevInfo: Bool = false
    @State var loggingEnabled: Bool = true
    @State var verboseLogging: Bool = false
    @State var selectedConfigPreset: ConfigPreset = .carTesting

    var body: some View {
        VStack(spacing: 16) {
            // Configuration Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Tracking Configuration")
                    .lexendFont(.bold, size: 18)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)

                // Config Preset Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preset:")
                        .lexendFont(.medium, size: 14)
                        .foregroundColor(.gray)

                    Picker("Configuration Preset", selection: $selectedConfigPreset) {
                        ForEach(ConfigPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedConfigPreset) { _, newPreset in
                        updateConfigurationPreset(newPreset)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("PrimaryColor").opacity(0.1))
                )

                // Logging Toggle
                ListRowWithToggle(
                    icon: "doc.text.fill",
                    iconColor: Color("SecondaryColor"),
                    title: "Enable Logging",
                    subtitle: "Show debug logs in console",
                    isOn: $loggingEnabled
                )
                .onChange(of: loggingEnabled) { _, newValue in
                    updateLoggingConfiguration()
                }

                // Verbose Logging Toggle
                ListRowWithToggle(
                    icon: "text.alignleft",
                    iconColor: Color("TertiaryColor"),
                    title: "Verbose Logging",
                    subtitle: "Include timestamps and metadata",
                    isOn: $verboseLogging
                )
                .disabled(!loggingEnabled)
                .opacity(loggingEnabled ? 1.0 : 0.5)
                .onChange(of: verboseLogging) { _, newValue in
                    updateLoggingConfiguration()
                }
            }
            .padding(.bottom, 20)

            Divider()

            // Debug Actions Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Debug Actions")
                    .lexendFont(.bold, size: 18)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)

                CustomButton(title: "Simulate Run", style: .tertiary, action: {
                    trackingManager.simulateRun()
                })
            }
            .padding(.bottom, 20)
            
            DangerButton(title: "Delete All Run Data", action: {
                showDeleteAlert = true
                print("button pressed")
            })
            .padding(.bottom, 50)
            
            Button(action: { showDevInfo.toggle() }) {
                VStack {
                    Text("SHOW DEV INFO")
                        .lexendFont(size: 20)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("PrimaryColor").opacity(0.2))
                )
            }
            
            if trackingManager.isRecording && showDevInfo {
                Text("Current Speed: \(Int(trackingManager.currentSpeed * 3.6)) km/h")
                    .font(.headline)
            
                Text("Elevation: \(Int(trackingManager.currentElevation))m")
                    .font(.subheadline)
            
                if trackingManager.currentRun != nil {
                    Text("🔴 In Run")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                } else {
                    Text("⚫ Between Runs")
                        .foregroundColor(.gray)
                }
            }

        }
        .alert("Delete All Local Run Data? You can not reverse this action", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                let runManager = RunManager(modelContext: modelContext)
                runManager.deleteAllRuns()
            }
        }
        .padding(.bottom, 50)
        .onAppear {
            // Initialize state from current config
            loggingEnabled = trackingManager.config.logging.isEnabled
            verboseLogging = trackingManager.config.logging.includeTimestamp
        }
    }

    // MARK: - Helper Methods

    private func updateConfigurationPreset(_ preset: ConfigPreset) {
        let newConfig: TrackingConfiguration

        switch preset {
        case .default:
            newConfig = .default
        case .carTesting:
            newConfig = .carTesting
        case .superLenient:
            newConfig = .superLenient
        case .highAccuracy:
            newConfig = .highAccuracy
        case .batterySaver:
            newConfig = .batterySaver
        }

        trackingManager.updateConfiguration(newConfig)

        // Update local state from new config
        loggingEnabled = newConfig.logging.isEnabled
        verboseLogging = newConfig.logging.includeTimestamp
    }

    private func updateLoggingConfiguration() {
        var updatedConfig = trackingManager.config

        // Update logging configuration
        updatedConfig.logging = LoggingConfig(
            isEnabled: loggingEnabled,
            minimumLevel: .debug,
            includeMetadata: true,
            includeTimestamp: verboseLogging
        )

        trackingManager.updateConfiguration(updatedConfig)
    }
}

// MARK: - Config Preset Enum

enum ConfigPreset: String, CaseIterable {
    case `default` = "default"
    case carTesting = "car_testing"
    case superLenient = "super_lenient"
    case highAccuracy = "high_accuracy"
    case batterySaver = "battery_saver"

    var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .carTesting:
            return "Car"
        case .superLenient:
            return "Lenient"
        case .highAccuracy:
            return "Accurate"
        case .batterySaver:
            return "Battery"
        }
    }
}

#Preview {
    DevSettingView(trackingManager: TrackingManager.preview)
}

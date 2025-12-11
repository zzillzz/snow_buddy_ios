//
//  ResortSelectionView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct ResortSelectionView: View {
    let group: GroupModel
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var trackingManager: TrackingManager

    @State private var searchText = ""
    @State private var resorts: [Resort] = []
    @State private var isLoading = false
    @State private var isStartingSession = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if resorts.isEmpty {
                    emptyState
                } else {
                    resortsList
                }
            }
            .navigationTitle("Select Resort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .lexendFont(.regular, size: 16)
                }
            }
            .searchable(text: $searchText, prompt: "Search resorts")
            .task {
                await loadResorts()
            }
            .onChange(of: searchText) { newValue in
                Task {
                    await loadResorts()
                }
            }
            .alert("Error Starting Session", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Failed to start session. Please try again.")
            }
        }
    }

    private var resortsList: some View {
        List {
            ForEach(resorts) { resort in
                Button {
                    startSession(at: resort)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(resort.name)
                                .lexendFont(.bold, size: 16)
                                .foregroundColor(.primary)

                            Text(resort.locationString)
                                .lexendFont(.regular, size: 13)
                                .foregroundColor(.secondary)

                            if let elevation = resort.elevationMeters {
                                HStack(spacing: 4) {
                                    Image(systemName: "mountain.2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(resort.elevationFormatted)
                                        .lexendFont(.regular, size: 12)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        if isStartingSession {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isStartingSession)
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))

            Text("No Resorts Found")
                .lexendFont(.bold, size: 18)

            Text("Try a different search term")
                .lexendFont(.regular, size: 14)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions
    private func loadResorts() async {
        isLoading = true
        resorts = await viewModel.searchResorts(query: searchText)
        isLoading = false
    }

    private func startSession(at resort: Resort) {
        isStartingSession = true

        Task {
            let sessionViewModel = GroupSessionViewModel(trackingManager: trackingManager)

            do {
                try await sessionViewModel.startSession(
                    groupId: group.id,
                    resortId: resort.id
                )

                await MainActor.run {
                    isStartingSession = false
                    dismiss()
                }
            } catch let error as GroupSessionError {
                await MainActor.run {
                    isStartingSession = false
                    errorMessage = error.errorDescription
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isStartingSession = false
                    errorMessage = "Failed to start session: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ResortSelectionView(
        group: GroupModel.sample,
        viewModel: GroupsViewModel()
    )
}

//
//  ResortPickerSheet.swift
//  snow-buddy
//
//  Created on 11/12/2025.
//

import SwiftUI

struct ResortPickerSheet: View {
    @Binding var selectedResort: Resort?
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var resorts: [Resort] = []
    @State private var isLoading = false

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

                ToolbarItem(placement: .confirmationAction) {
                    if selectedResort != nil {
                        Button("Clear") {
                            selectedResort = nil
                            dismiss()
                        }
                        .lexendFont(.regular, size: 16)
                        .foregroundColor(.red)
                    }
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
        }
    }

    private var resortsList: some View {
        List {
            ForEach(resorts) { resort in
                Button {
                    selectResort(resort)
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

                        // Show checkmark for selected resort
                        if selectedResort?.id == resort.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                    .padding(.vertical, 4)
                }
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

    private func selectResort(_ resort: Resort) {
        selectedResort = resort
        dismiss()
    }
}

#Preview {
    ResortPickerSheet(
        selectedResort: .constant(nil),
        viewModel: GroupsViewModel()
    )
}

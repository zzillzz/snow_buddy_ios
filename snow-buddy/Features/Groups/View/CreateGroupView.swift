//
//  CreateGroupView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 10/12/2025.
//

import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var isPrivate = false
    @State private var maxMembers = 8
    @State private var selectedResort: Resort?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .lexendFont(.regular, size: 16)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...6)
                        .lexendFont(.regular, size: 16)
                } header: {
                    Text("Group Details")
                        .lexendFont(.semiBold, size: 14)
                }

                Section {
                    ResortPickerField(
                        selectedResort: $selectedResort,
                        viewModel: viewModel
                    )
                } header: {
                    Text("Resort")
                        .lexendFont(.semiBold, size: 14)
                } footer: {
                    Text("Set a default resort for this group. Sessions can be at any resort.")
                        .lexendFont(.regular, size: 12)
                }

                Section {
                    Toggle("Private Group", isOn: $isPrivate)
                        .lexendFont(.regular, size: 16)

                    HStack {
                        Text("Max Members")
                            .lexendFont(.regular, size: 16)

                        Spacer()

                        Text("\(maxMembers)")
                            .lexendFont(.semiBold, size: 16)
                            .foregroundColor(.secondary)
                    }

                    Text("Free tier is limited to 8 members per group")
                        .lexendFont(.regular, size: 12)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Settings")
                        .lexendFont(.semiBold, size: 14)
                } footer: {
                    Text("Private groups can only be joined by invitation")
                        .lexendFont(.regular, size: 12)
                }

                if isCreating {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .padding()
                    .listRowBackground(Color.clear)
                } else {
                    PrimaryActionButton(
                        title: "Create Group",
                        icon: "plus.circle.fill"
                    ) {
                        createGroup()
                    }
                    .disabled(name.isEmpty)
                    .listRowBackground(Color.clear)
                }

            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .lexendFont(.regular, size: 16)
                }
            }
        }
    }

    private func createGroup() {
        isCreating = true

        Task {
            do {
                print("🔵 CreateGroupView: Starting group creation")
                print("🔵 Name: \(name)")
                print("🔵 Description: \(description.isEmpty ? "nil" : description)")
                print("🔵 MaxMembers: \(maxMembers)")
                print("🔵 IsPrivate: \(isPrivate)")
                print("🔵 DefaultResortId: \(selectedResort?.id.uuidString ?? "nil")")

                try await viewModel.createGroup(
                    name: name,
                    description: description.isEmpty ? nil : description,
                    maxMembers: maxMembers,
                    isPrivate: isPrivate,
                    defaultResortId: selectedResort?.id
                )

                print("✅ CreateGroupView: Group created successfully")
                await MainActor.run {
                    isCreating = false
                    // Delay dismiss to avoid alert presentation conflict
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        dismiss()
                    }
                }
            } catch {
                print("❌ CreateGroupView: Error creating group: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                await MainActor.run {
                    isCreating = false
                }
            }
        }
    }
}

#Preview {
    CreateGroupView(viewModel: GroupsViewModel())
}

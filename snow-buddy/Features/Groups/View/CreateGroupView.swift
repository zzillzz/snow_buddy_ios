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

                Section {
                    Button {
                        createGroup()
                    } label: {
                        if isCreating {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                        } else {
                            Text("Create Group")
                                .lexendFont(.semiBold, size: 16)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isCreating)
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
                try await viewModel.createGroup(
                    name: name,
                    description: description.isEmpty ? nil : description,
                    maxMembers: maxMembers,
                    isPrivate: isPrivate
                )
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
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

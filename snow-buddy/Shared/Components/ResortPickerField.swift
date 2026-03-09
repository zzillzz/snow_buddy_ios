//
//  ResortPickerField.swift
//  snow-buddy
//
//  Created on 11/12/2025.
//

import SwiftUI

struct ResortPickerField: View {
    @Binding var selectedResort: Resort?
    @ObservedObject var viewModel: GroupsViewModel

    @State private var showResortSelection = false

    var body: some View {
        Button {
            showResortSelection = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Resort (Optional)")
                        .lexendFont(.regular, size: 14)
                        .foregroundColor(.secondary)

                    if let resort = selectedResort {
                        Text(resort.name)
                            .lexendFont(.semiBold, size: 16)
                            .foregroundColor(.primary)

                        Text(resort.locationString)
                            .lexendFont(.regular, size: 13)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Tap to select a resort")
                            .lexendFont(.regular, size: 16)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: selectedResort == nil ? "plus.circle" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(selectedResort == nil ? .gray : Color("PrimaryColor"))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showResortSelection) {
            ResortPickerSheet(
                selectedResort: $selectedResort,
                viewModel: viewModel
            )
        }
    }
}

#Preview {
    Form {
        Section {
            ResortPickerField(
                selectedResort: .constant(nil),
                viewModel: GroupsViewModel()
            )
        } header: {
            Text("Resort")
                .lexendFont(.semiBold, size: 14)
        }
    }
}

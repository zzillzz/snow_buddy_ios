//
//  FriendsView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 2/12/2025.
//

import SwiftUI

struct FriendsView: View {

    @State private var tabSelectedValue = 0
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Heading
            PageHeading(text: "Friends")

            // Segmented Tabs
            Picker("Tabs", selection: $tabSelectedValue) {
                Text("Friends").tag(0)
                Text("Requests").tag(1)
                Text("Recieved").tag(2)
            }
            .pickerStyle(.segmented)

            // Page Content
            TabView(selection: $tabSelectedValue) {

                FriendsTab(
                    friends: viewModel.friends,
                    isLoading: viewModel.isLoading
                )
                .tag(0)

                FriendRequestTab(viewModel: viewModel)
                    .tag(1)
                
                FriendRecievedTab(viewModel: viewModel)
                    .tag(2)
            }
            .tabViewStyle(.page)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .padding()
        .appBackground()
        .task {
            viewModel.isLoading = true
            await viewModel.loadData()
        }
    }
}




#Preview {
    FriendsView()
}

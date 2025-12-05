//
//  FriendRecievedTab.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 5/12/2025.
//

import SwiftUI

struct FriendRecievedTab: View {
    @ObservedObject var viewModel: FriendsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.receivedRequests.isEmpty && viewModel.sentRequests.isEmpty {
                VStack {
                    Text("No pending requests")
                        .lexendFont(size: 17)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        //MARK: Received Requests Section
                        if !viewModel.receivedRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Received Requests")
                                    .lexendFont(.bold, size: 18)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)

                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.receivedRequests, id: \.id) { request in
                                        if let sender = request.sender {
                                            UserCard(user: sender)
                                                .overlay(alignment: .trailing) {
                                                    HStack(spacing: 8) {
                                                        AcceptRequestButton(action: {
                                                            Task {
                                                                await viewModel.acceptFriendRequest(requestId: request.id)
                                                            }
                                                        })

                                                        RejectRequestButton(action: {
                                                            Task {
                                                                await viewModel.rejectFriendRequest(requestId: request.id)
                                                            }
                                                        })
                                                    }
                                                    .padding(.trailing, 20)
                                                }
                                        }
                                    }
                                }
                            }
                        }

                        //MARK: Sent Requests Section
                        if !viewModel.sentRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sent Requests")
                                    .lexendFont(.bold, size: 18)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)

                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.sentRequests, id: \.id) { request in
                                        if let receiver = request.receiver {
                                            UserCard(user: receiver)
                                                .overlay(alignment: .trailing) {
                                                    CancelRequestButton(action: {
                                                        Task {
                                                            await viewModel.cancelFriendRequest(requestId: request.id)
                                                        }
                                                    })
                                                    .padding(.trailing, 20)
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}


#Preview {
    //FriendRecievedTab()
}

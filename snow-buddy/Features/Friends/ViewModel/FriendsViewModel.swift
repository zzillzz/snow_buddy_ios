//
//  FriendsViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/12/2025.
//
import Foundation
import Supabase

@MainActor
protocol FriendsViewModelProtocol {
    var friends: [User] { get set }
    var receivedRequests: [FriendRequest] { get set }
    var sentRequests: [FriendRequest] { get set }
    var isLoading: Bool { get set }
    
    func loadData() async
}

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
class FriendsViewModel: FriendsViewModelProtocol, ObservableObject  {
    @Published var friends: [User] = []
    @Published var receivedRequests: [FriendRequest] = []
    @Published var sentRequests: [FriendRequest] = []
    @Published var isLoading: Bool = false
    
//    @Published var errorMessage: String?
//    @Published var successMessage: String?
//    @Published var showAlert = false
    
    @Published var alertConfig: AlertConfig?

    func loadData() async {
        guard let userId = try? await SupabaseService.shared
                .getAuthenticatedUser().id
        else {
            isLoading = false
            return
        }

        do {
            friends = try await FriendsService.shared.getFriends(userId: userId)
            
            receivedRequests = try await FriendsService.shared
                .getReceivedFriendRequests(userId: userId)

            sentRequests = try await FriendsService.shared.getSentFriendRequests(
                userId: userId
            )
            
            isLoading = false
        } catch (_) {
            print("something went wrong")
            isLoading = false
        }
    }
    
    func searchUser(with userName: String) async -> [User] {
        do {
            let users = try await FriendsService.shared.searchUsers(query: userName)
            return users
        } catch {
            print("could not search user")
        }
        
        return []
    }
    
//    func sendFriendRequest(to friendUserId: UUID) async {
//        guard let userId = try? await SupabaseService.shared.getAuthenticatedUser().id
//        else {
//            await MainActor.run {
//                errorMessage = "Unable to send friend request. Please log in again."
//                showAlert = true
//            }
//            return
//        }
//
//        do {
//            try await FriendsService.shared.sendFriendRequest(from: userId, to: friendUserId)
//            
//            await MainActor.run {
//                successMessage = "Friend request sent!"
//                showAlert = true
//                // Optional: Update relationship status or refresh data
//                // Task { await loadUserData() }
//            }
//        } catch let error as FriendRequestError {
//            await MainActor.run {
//                errorMessage = error.errorDescription
//                showAlert = true
//            }
//        } catch {
//            await MainActor.run {
//                errorMessage = "Failed to send friend request. Please try again."
//                showAlert = true
//            }
//            print("could not send friend request")
//        }
//    }
    
    func sendFriendRequest(to friendUserId: UUID) async {
        guard let userId = try? await SupabaseService.shared.getAuthenticatedUser().id else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Unable to send friend request. Please log in again."
                )
            }
            return
        }

        do {
            try await FriendsService.shared.sendFriendRequest(from: userId, to: friendUserId)

            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Success",
                    message: "Friend request sent!"
                )
            }

        } catch let error as FriendRequestError {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Unable to Send",
                    message: error.errorDescription ?? "Unknown error"
                )
            }

        } catch {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "Error",
                    message: "Failed to send friend request. Please try again."
                )
            }
        }
    }

    func cancelFriendRequest(requestId: UUID) async {
        do {
            try await FriendsService.shared.cancelFriendRequest(requestId: requestId)
            // Reload data to refresh the sent requests list
            await loadData()
        } catch {
            print("Failed to cancel friend request: \(error)")
        }
    }

    func acceptFriendRequest(requestId: UUID) async {
        do {
            try await FriendsService.shared.acceptFriendRequest(requestId: requestId)
            // Reload data to refresh the requests and friends lists
            await loadData()
        } catch {
            print("Failed to accept friend request: \(error)")
        }
    }

    func rejectFriendRequest(requestId: UUID) async {
        do {
            try await FriendsService.shared.rejectFriendRequest(requestId: requestId)
            // Reload data to refresh the requests list
            await loadData()
        } catch {
            print("Failed to reject friend request: \(error)")
        }
    }
}

//
//  HomeViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 22/9/2025.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    let supabaseService = SupabaseService.shared
    
    @Published var isLoading: Bool = false
    @Published var user: User?
    
    func loadUser() async {
        do {
            let authUser = try await supabaseService.getAuthenticatedUser()
            user = try await supabaseService.getUserData(userId: authUser.id)
        } catch {
            print("could not get user")
        }
    }
    
    func logOutUser() {
        Task {
            do {
                isLoading = true
                defer { isLoading = false }
                try await supabaseService.logOutUser()
            } catch {
                print("Something went wrong")
            }
        }
    }
    
}

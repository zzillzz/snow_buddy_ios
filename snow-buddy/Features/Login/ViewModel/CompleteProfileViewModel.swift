//
//  CompleteProfileViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 22/9/2025.
//
import Foundation

@MainActor
class CompleteProfileViewModel: ObservableObject {
    let supabaseService = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var usernameUpdated: Bool = false


    func saveUsername(username: String) {
        Task {
            do {
                isLoading = true
                defer { isLoading = false }
                
                let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    // maybe send back inline error message
                    return
                }
                
                let user = try await supabaseService.getAuthenticatedUser()

                try await supabaseService.updateUserUsername(userId: user.id, username: username)
                usernameUpdated = true
            } catch {
                usernameUpdated = false
                print("Tried Updating User Username but failed: \(error)")
            }
        }
    }
    
    func logUserOut() {
        Task {
            do {
                try await supabaseService.logOutUser()
            } catch {
                print("error logging user out \(error)")
            }
            
        }
        
    }
}


//
//  LoginViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 20/9/2025.
//

import Foundation
import SwiftUICore

@MainActor
class LoginViewModel: ObservableObject {
    
    let supabaseService = SupabaseService.shared
    
    @Published var email: String = ""
    @Published var loginResult: Result<Void, Error>?
        
    // Output state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    
    func signInButtonTapped() {
        print("button pressed yay")
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await supabaseService.signUpWithOtp(email: email)
                loginResult = .success(())
            } catch {
                loginResult = .failure(error)
            }
        }
        
    }
    
    func handleAuthCallback(url: URL) {
        Task {
            do {
                try await supabaseService.setUpUserSession(url: url)
            } catch {
                loginResult = .failure(error)
            }
            
        }
    }
}

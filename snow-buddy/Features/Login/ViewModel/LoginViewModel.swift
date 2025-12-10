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
    @Published var isLoading: Bool = false
    @Published var emailSent: Bool = false

    func signInButtonTapped() {
        Task {
            isLoading = true
            emailSent = false
            defer { isLoading = false }

            do {
                try await supabaseService.signUpWithOtp(email: email)
                loginResult = .success(())
                emailSent = true
            } catch {
                loginResult = .failure(error)
            }
        }
    }
}

//
//  EmailVerificationViewModel.swift
//  snow-buddy
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

@MainActor
class EmailVerificationViewModel: ObservableObject {
    let supabaseService = SupabaseService.shared

    // Input
    let email: String

    // Output State
    @Published var otpCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var verificationAttempts: Int = 0
    @Published var canResend: Bool = false
    @Published var remainingSeconds: Int = 60
    @Published var shouldNavigateBack: Bool = false
    @Published var isVerified: Bool = false

    // Constants
    private let maxAttempts = 3
    private let resendCooldownSeconds = 60
    private var resendTimer: Timer?

    init(email: String) {
        self.email = email
        startResendTimer()
    }

    deinit {
        resendTimer?.invalidate()
    }

    // MARK: - Public Methods

    func verifyOTP() async {
        guard otpCode.count == 6 else {
            errorMessage = "Please enter a 6-digit code"
            return
        }

        guard verificationAttempts < maxAttempts else {
            errorMessage = "Too many failed attempts. Please request a new code."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabaseService.verifyOTP(email: email, token: otpCode)
            isVerified = true
            errorMessage = nil
        } catch {
            verificationAttempts += 1

            if verificationAttempts >= maxAttempts {
                errorMessage = "Maximum attempts reached. Returning to login..."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.shouldNavigateBack = true
                }
            } else {
                let remaining = maxAttempts - verificationAttempts
                errorMessage = "Invalid code. \(remaining) attempt\(remaining == 1 ? "" : "s") remaining."
                otpCode = "" // Clear for retry
            }
        }
    }

    func resendCode() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                try await supabaseService.signUpWithOtp(email: email)
                verificationAttempts = 0 // Reset attempts
                canResend = false
                remainingSeconds = resendCooldownSeconds
                startResendTimer()
            } catch {
                errorMessage = "Failed to resend code. Please try again."
            }
        }
    }

    func handleAuthCallback(url: URL) async {
        // Prevent duplicate session setup if already verified via OTP
        guard !isVerified else {
            print("Already verified via OTP, ignoring magic link")
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabaseService.setUpUserSession(url: url)
            isVerified = true
        } catch {
            errorMessage = "Failed to verify magic link: \(error.localizedDescription)"
        }
    }

    func openEmailApp() {
        if let url = URL(string: "message://") {
            UIApplication.shared.open(url)
        }
    }

    func backToLogin() {
        shouldNavigateBack = true
    }

    // MARK: - Private Methods

    private func startResendTimer() {
        resendTimer?.invalidate()
        canResend = false
        remainingSeconds = resendCooldownSeconds

        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            DispatchQueue.main.async {
                self.remainingSeconds -= 1

                if self.remainingSeconds <= 0 {
                    self.canResend = true
                    timer.invalidate()
                }
            }
        }
    }
}

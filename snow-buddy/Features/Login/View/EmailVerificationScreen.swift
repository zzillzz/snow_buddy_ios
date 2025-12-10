//
//  EmailVerificationScreen.swift
//  snow-buddy
//
//  Created by Claude Code
//

import SwiftUI

struct EmailVerificationScreen: View {
    @StateObject private var viewModel: EmailVerificationViewModel
    @Environment(\.dismiss) private var dismiss

    init(email: String) {
        _viewModel = StateObject(wrappedValue: EmailVerificationViewModel(email: email))
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Logo
            Image("LogoWithText")
                .padding(.bottom, 20)

            // Title
            Text("Check Your Email")
                .foregroundStyle(Color("PrimaryColor"))
                .lexendFont(.bold, size: 32)

            // Instructions
            VStack(spacing: 8) {
                Text("We've sent a verification code to:")
                    .lexendFont(size: 16)
                    .multilineTextAlignment(.center)

                Text(viewModel.email)
                    .foregroundStyle(Color("PrimaryColor"))
                    .lexendFont(.bold, size: 18)

                Text("Enter the 6-digit code or tap the magic link in your email")
                    .lexendFont(size: 14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
            .padding(.bottom, 30)

            // OTP Input
            OTPCodeInputView(code: $viewModel.otpCode)
                .padding(.horizontal, 40)

            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .lexendFont(size: 14)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .transition(.opacity)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.vertical, 8)
                } else {
                    CustomButton(
                        title: "Verify Code",
                        isDisabled: viewModel.otpCode.count != 6,
                        action: {
                            Task { await viewModel.verifyOTP() }
                        }
                    )
                    .padding(.horizontal, 40)
                }

                // Resend Code
                if viewModel.canResend {
                    CustomButton(
                        title: "Resend Code",
                        style: .secondary,
                        action: { viewModel.resendCode() }
                    )
                    .padding(.horizontal, 40)
                } else {
                    Text("Resend code in \(viewModel.remainingSeconds)s")
                        .lexendFont(size: 14)
                        .foregroundStyle(.secondary)
                }

                // Open Email App
                CustomButton(
                    title: "Open Email App",
                    style: .tertiary,
                    action: { viewModel.openEmailApp() }
                )
                .padding(.horizontal, 40)

                // Back to Login
                Button("Back to Login") {
                    viewModel.backToLogin()
                }
                .lexendFont(size: 16)
                .foregroundStyle(Color("PrimaryColor"))
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
        .appBackground()
        .onOpenURL { url in
            Task { await viewModel.handleAuthCallback(url: url) }
        }
        .onChange(of: viewModel.shouldNavigateBack) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

#Preview {
    EmailVerificationScreen(email: "test@example.com")
}

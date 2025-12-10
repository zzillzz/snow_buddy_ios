//
//  LoginScreen.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 19/9/2025.
//

import SwiftUI

struct LoginScreen: View {

    @StateObject private var viewModel = LoginViewModel()
    @State private var showVerificationScreen = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Image("LogoWithText")
                .padding(.bottom, 40)
            
            Text("Welcome")
                .foregroundStyle(Color("PrimaryColor"))
                .lexendFont(.bold, size: 40)
            
            Text("Login to your account or create a new one to start tracking your runs")
                .padding(.leading, 40)
                .padding(.trailing, 40)
                .multilineTextAlignment(.center)
                .lexendFont(size: 18)
            
            VStack{
                CustomTextField(placeholder: "email:", text: $viewModel.email)
                
                CustomButton(title: "Login In Or Create Account", action: {viewModel.signInButtonTapped()})
            }.padding(.horizontal, 40)
            
            if viewModel.isLoading {
                ProgressView()
            }

            if case .failure(let error) = viewModel.loginResult {
                Text("Error: \(error.localizedDescription)")
                    .foregroundStyle(.red)
                    .lexendFont(size: 14)
                    .padding(.top, 8)
            }

        }
        .appBackground()
        .onChange(of: viewModel.emailSent) { oldValue, newValue in
            if newValue {
                showVerificationScreen = true
            }
        }
        .fullScreenCover(isPresented: $showVerificationScreen) {
            EmailVerificationScreen(email: viewModel.email)
        }
    }
}

#Preview {
    LoginScreen()
    
}


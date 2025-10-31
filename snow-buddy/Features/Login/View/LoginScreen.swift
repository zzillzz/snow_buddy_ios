//
//  LoginScreen.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 19/9/2025.
//

import SwiftUI

struct LoginScreen: View {
    
    @StateObject private var viewModel = LoginViewModel()
    @State private var alertText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            Image("LogoWithText")
                .padding(.bottom, 40)
            
            Text("Welcome")
                .foregroundStyle(Color("Primary"))
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

            if let result = viewModel.loginResult {
                VStack{
                    switch result {
                    case .success:
                        Text("Success Email Sent")
                    case .failure(let error):
                        Text("Failure \(error.localizedDescription)").foregroundStyle(.red)
                    }
                }}
            
        }
        .appBackground()
        .onOpenURL(perform: {url in
            Task {
                viewModel.handleAuthCallback(url: url)
            }
        })
    }
}

#Preview {
    LoginScreen()
    
}


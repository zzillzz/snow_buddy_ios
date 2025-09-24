//
//  LoginScreen.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 19/9/2025.
//

import SwiftUI

struct LoginScreen: View {
    // @State private var selectedSegment: String = "createAccount"
    
    @StateObject private var viewModel = LoginViewModel()
    @State private var showingAlert = false
    @State private var alertText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            Image("LogoWithText")
                .padding(.bottom, 40)
            
            Text("Welcome")
                .foregroundStyle(ColorConfig.grape)
                .font(.system(size: 24, weight: .bold, design: .default))
            
            Text("Login to your account or create a new one to start tracking your runs")
                .padding(.leading, 40)
                .padding(.trailing, 40)
                .multilineTextAlignment(.center)
            
            VStack{
                TextField("email:", text: $viewModel.email)
                    .autocapitalization(.none)
                    .padding()
                    .background(isFocused ? Color.white : Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .focused($isFocused)
                    .animation(.easeIn(duration: 0.1), value: isFocused)
                                
                Button(action: { viewModel.signInButtonTapped() }) {
                    Text("Login In Or Create Account")
                        .foregroundColor(Color.white)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .frame(maxWidth: .infinity, maxHeight: 10)
                }
                .padding()
                .background(ColorConfig.cardinal)
                .cornerRadius(20)
                .disabled(viewModel.isLoading)
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
        .onOpenURL(perform: {url in
            Task {
                viewModel.handleAuthCallback(url: url)
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [ColorConfig.white, ColorConfig.wisteria]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .alert("Important message", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                }
    }
}

#Preview {
    LoginScreen()
}


//
//  CompleteProfileView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 22/9/2025.
//

import SwiftUI

struct CompleteProfileView: View {
    
    @StateObject var viewModel = CompleteProfileViewModel()
    @State var username = ""
    @FocusState private var isFocused: Bool
    @State private var attempts = 0
    var onFinished: () -> Void
    
    var body: some View {
        VStack {
            Text("Lets complete you’re profile")
                .foregroundStyle(ColorConfig.grape)
                .font(.system(size: 64, weight: .bold, design: .default))
                .padding(.bottom)
                .padding(.top)
                .padding(.leading, -40)
            
            Text("This is info that people riding with you will be able to see. Feel free to put in a nickname as your username!")
                .padding(.bottom)
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                TextField("username:", text: $username)
                    .autocapitalization(.none)
                    .padding()
                    .background(isFocused ? Color.white : Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .focused($isFocused)
                    .animation(.easeIn(duration: 0.1), value: isFocused)
                    .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
                
            }
            
            Spacer()
            
            Button(action: viewModel.logUserOut) {
                Text("Log User out")
            }
            Button(action: {
                let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    withAnimation(.default) {
                        attempts += 1
                    }
                    return
                }
                viewModel.saveUsername(username: username)
            }) {
                Text("Complete Profile")
                    .foregroundColor(Color.white)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .frame(maxWidth: .infinity, maxHeight: 10)
            }
            .padding()
            .background(ColorConfig.cardinal)
            .cornerRadius(20)
            .disabled(viewModel.isLoading)
            .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [ColorConfig.white, ColorConfig.wisteria]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onChange(of: viewModel.usernameUpdated, initial: false, { onFinished() })
    }
}

#Preview {
    CompleteProfileView(onFinished : { print("Username updated") })
}

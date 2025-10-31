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
                .lexendFont(.bold, size: 64)
                .padding(.bottom)
                .padding(.top)
            
            Text("This is info that people riding with you will be able to see. Feel free to put in a nickname as your username!")
                .padding(.bottom)
                .lexendFont(size: 18)
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                CustomTextField(placeholder: "username", text: $username)
                    .animation(.easeIn(duration: 0.1), value: isFocused)
                    .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
                
            }
            
            Spacer()
            
            Button(action: viewModel.logUserOut) {
                Text("DEV TOOL: Log User out")
            }
            
            CustomButton(title: "Complete Profile", action: {
                let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    withAnimation(.default) {
                        attempts += 1
                    }
                    return
                }
                viewModel.saveUsername(username: username)
            })
            .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 40)
        .appBackground()
        .onChange(of: viewModel.usernameUpdated, initial: false, { onFinished() })
    }
}

#Preview {
    CompleteProfileView(onFinished : { print("Username updated") })
}

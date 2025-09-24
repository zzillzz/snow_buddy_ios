//
//  HomeView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 20/9/2025.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State var username = "User"
    
    var body: some View {
        VStack {
            Text("Welcome \(username)")
            
            Button(action: { viewModel.logOutUser() }) {
                Text("Log Out")
                    .foregroundColor(Color.white)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .frame(maxWidth: .infinity, maxHeight: 10)
            }
            .padding()
            .background(ColorConfig.cardinal)
            .cornerRadius(20)
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 40)
        .task {
            await viewModel.loadUser() 
            if let userName = viewModel.user?.username {
                username = userName
            }
        }
    }
}

#Preview {
    HomeView()
}

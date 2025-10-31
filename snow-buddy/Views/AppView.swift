//
//  AppView.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 20/9/2025.
//

import SwiftUI
import Supabase

struct AppView: View {
    @State var isAuthenticated = false
    @StateObject var appViewModel = AppViewModel()
    @State var needsProfileSetup: Bool = false
    @State var isLoading = true
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if isLoading {
                SplashScreen()
                    .transition(.opacity)
            } else if !isAuthenticated {
                LoginScreen()
                    .transition(.slideAndFade)
            } else if needsProfileSetup {
                CompleteProfileView(onFinished: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        needsProfileSetup = false
                    }
                })
                .transition(.slideAndFade)
            } else {
                HomeView()
                    .transition(.pushUp)
                    .environment(\.modelContext, modelContext) 
            }

        }
        .task {
            for await state in await appViewModel.sendAuthState() {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    withAnimation(.easeInOut(duration: 0.6)){
                        if let _ = state.session {
                            isAuthenticated = true
                            isLoading = false
                        } else {
                            isAuthenticated = false
                            needsProfileSetup = false
                            isLoading = false
                        }
                    }
                    if let session = state.session {
                        let hasNoUsername = await appViewModel.hasUsername(id: session.user.id) == false
                        withAnimation(.easeInOut(duration: 0.6)){
                            needsProfileSetup = hasNoUsername
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
}


class AppViewModel: ObservableObject {
    let supabaseService = SupabaseService.shared

    func sendAuthState() async -> AsyncStream<
        (
          event: AuthChangeEvent,
          session: Session?
        )
      > {
          return await supabaseService.authStateChange()
    }
    
    func hasUsername(id: UUID) async -> Bool {
        do {
            let user: User = try await supabaseService.getUserData(userId: id)
            if user.username == nil {
                return false
            } else {
                return true
            }
        } catch {
            print("Something went wrong could not get user profile \(error)")
        }
        
        return false
    }
}

#Preview {
    AppView()
}

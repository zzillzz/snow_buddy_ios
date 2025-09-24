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

    var body: some View {
        Group {
            if !isAuthenticated {
                LoginScreen()
            } else if needsProfileSetup {
                CompleteProfileView(onFinished: {
                    needsProfileSetup = false
                })
            } else {
                HomeView()
            }

        }
        .task {
            for await state in await appViewModel.sendAuthState() {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    if let session = state.session {
                        isAuthenticated = true
                        needsProfileSetup = await appViewModel.hasUsername(id: session.user.id) == false
                    } else {
                        isAuthenticated = false
                        needsProfileSetup = false
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

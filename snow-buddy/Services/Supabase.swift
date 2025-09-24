//
//  Supabase.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 15/9/2025.
//
import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        print("🔧 Environment: \(SupabaseConfig.currentEnvironment)")
        print("🔗 Supabase URL: \(SupabaseConfig.url)")
        
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL: \(SupabaseConfig.url)")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    // Auth methods
    func getAuthenticatedUser() async throws -> Auth.User {
        return try await client.auth.session.user
    }
    
    func signUpWithOtp(email: String) async throws {
        try await client.auth.signInWithOTP(email: email, redirectTo: URL(string: "snow-buddy-app://auth-callback"));
    }
    
    func setUpUserSession(url: URL) async throws {
        try await client.auth.session(from: url)
    }
    
    func authStateChange() async -> AsyncStream<
        (
          event: AuthChangeEvent,
          session: Session?
        )
      > {
        return client.auth.authStateChanges
    }
    
    func logOutUser() async throws {
        try await client.auth.signOut()
    }
    
    func getUserData(userId: UUID) async throws -> User {
        let user: User = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return user
    }
    
    func updateUserUsername(userId: UUID, username: String) async throws {
        try await client
            .from("users")
            .update(["username": username])
            .eq("id", value: userId)
            .execute()
    }
}

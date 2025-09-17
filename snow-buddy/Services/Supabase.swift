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
}

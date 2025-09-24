//
//  UserModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 22/9/2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let username: String?
}

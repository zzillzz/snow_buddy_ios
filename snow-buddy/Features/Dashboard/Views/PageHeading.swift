//
//  PageHeading.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/11/2025.
//
import Foundation
import SwiftUI

struct UserNameHeading: View {
    var username: String
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome").lexendFont(.extraBold, size: 25)
            Text("\(username)!").lexendFont(.extraBold, size: 25)
        }
    }
}

struct PageHeading: View {
    var text: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(text).lexendFont(.extraBold, size: 25)
        }
    }
}

#Preview {
    UserNameHeading(username: "aUserName")
    PageHeading(text: "Page Heading")
}



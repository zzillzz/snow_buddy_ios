//
//  CustomBackground.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 3/10/2025.
//

import SwiftUI

struct CustomBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Background"))
    }
}

extension View {
    func appBackground() -> some View {
        self.modifier(CustomBackground())
    }
}

#Preview {
    VStack {
        Color("Background")
    }
}

//
//  RunListViewModel.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 12/10/2025.
//

import Foundation
import SwiftData

class RunListViewModel: ObservableObject {
    @Published var runs: [Run] = []
}

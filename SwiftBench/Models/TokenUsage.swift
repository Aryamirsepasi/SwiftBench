//
//  TokenUsage.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

struct TokenUsage: Hashable {
    let prompt: Int
    let completion: Int
    let total: Int
}

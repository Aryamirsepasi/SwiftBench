//
//  BenchmarkScoreComponent.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

struct BenchmarkScoreComponent: Identifiable, Hashable {
    let id: String
    let label: String
    let value: Double
    let weight: Double
}

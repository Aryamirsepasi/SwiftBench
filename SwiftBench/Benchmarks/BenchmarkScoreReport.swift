//
//  BenchmarkScoreReport.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

struct BenchmarkScoreReport: Hashable {
    let score: Double
    let components: [BenchmarkScoreComponent]
}

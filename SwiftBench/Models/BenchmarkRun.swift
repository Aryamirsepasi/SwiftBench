//
//  BenchmarkRun.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation
import SwiftData

@Model
final class BenchmarkRun {
    var id = UUID()
    var createdAt = Date.now
    var benchmarkID = ""
    var benchmarkTitle = ""
    var modelIdentifier = ""
    var provider: String?
    var prompt = ""
    var response = ""
    var score = 0.0
    var tokenPrompt = 0
    var tokenCompletion = 0
    var tokenTotal = 0

    init(
        benchmarkID: String,
        benchmarkTitle: String,
        modelIdentifier: String,
        provider: String?,
        prompt: String,
        response: String,
        score: Double,
        tokenPrompt: Int,
        tokenCompletion: Int,
        tokenTotal: Int
    ) {
        self.benchmarkID = benchmarkID
        self.benchmarkTitle = benchmarkTitle
        self.modelIdentifier = modelIdentifier
        self.provider = provider
        self.prompt = prompt
        self.response = response
        self.score = score
        self.tokenPrompt = tokenPrompt
        self.tokenCompletion = tokenCompletion
        self.tokenTotal = tokenTotal
    }
}

//
//  SuiteRunResult.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation
import SwiftData

/// Aggregated results from running a complete benchmark suite.
@Model
final class SuiteRunResult {
    // MARK: - Identity

    var id = UUID()
    var createdAt = Date.now

    // MARK: - Suite Info

    /// The suite ID that was executed.
    var suiteID = ""

    /// The version of the suite.
    var suiteVersion = ""

    /// The title of the suite.
    var suiteTitle = ""

    // MARK: - Model Info

    /// The model identifier used for this suite run.
    var modelIdentifier = ""

    /// The provider that served the model (e.g., "OpenAI", "Anthropic").
    var provider: String?

    // MARK: - Aggregate Metrics

    /// Fraction of tasks passing on first attempt (0.0 to 1.0).
    var passAt1 = 0.0

    /// Fraction of tasks passing in k attempts (0.0 to 1.0).
    var passAtK = 0.0

    /// Number of attempts per task.
    var kValue = 1

    /// Mean score across all tasks.
    var meanScore = 0.0

    /// Variance of scores.
    var scoreVariance = 0.0

    /// Mean style score across all tasks.
    var meanStyleScore = 0.0

    // MARK: - Category Breakdown

    /// JSON-encoded category metrics.
    var categoryResultsJSON: String?

    // MARK: - Token Usage

    /// Total tokens used across all runs.
    var totalTokensUsed = 0

    /// Estimated cost in USD (if available).
    var estimatedCost: Double?

    // MARK: - Run Configuration

    /// Temperature used for generation.
    var temperature = 0.7

    /// Total number of tasks in the suite.
    var totalTasks = 0

    /// Number of tasks that passed.
    var passedTasks = 0

    /// Total execution time in seconds.
    var totalExecutionTime = 0.0

    // MARK: - Computed Properties

    /// Category metrics decoded from JSON.
    var categoryResults: [CategoryMetrics] {
        get {
            guard let json = categoryResultsJSON,
                  let data = json.data(using: .utf8),
                  let metrics = try? JSONDecoder().decode([CategoryMetrics].self, from: data)
            else {
                return []
            }
            return metrics
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                categoryResultsJSON = json
            } else {
                categoryResultsJSON = nil
            }
        }
    }

    /// Pass@1 as a percentage.
    var passAt1Percentage: Double {
        passAt1 * 100
    }

    /// Pass@k as a percentage.
    var passAtKPercentage: Double {
        passAtK * 100
    }

    /// Overall pass rate as a percentage.
    var passRatePercentage: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(passedTasks) / Double(totalTasks) * 100
    }

    // MARK: - Initializers

    init() {}

    init(
        suiteID: String,
        suiteVersion: String,
        suiteTitle: String,
        modelIdentifier: String,
        provider: String?,
        passAt1: Double,
        passAtK: Double,
        kValue: Int,
        meanScore: Double,
        scoreVariance: Double,
        meanStyleScore: Double,
        categoryResults: [CategoryMetrics],
        totalTokensUsed: Int,
        estimatedCost: Double?,
        temperature: Double,
        totalTasks: Int,
        passedTasks: Int,
        totalExecutionTime: Double
    ) {
        self.suiteID = suiteID
        self.suiteVersion = suiteVersion
        self.suiteTitle = suiteTitle
        self.modelIdentifier = modelIdentifier
        self.provider = provider
        self.passAt1 = passAt1
        self.passAtK = passAtK
        self.kValue = kValue
        self.meanScore = meanScore
        self.scoreVariance = scoreVariance
        self.meanStyleScore = meanStyleScore
        self.categoryResults = categoryResults
        self.totalTokensUsed = totalTokensUsed
        self.estimatedCost = estimatedCost
        self.temperature = temperature
        self.totalTasks = totalTasks
        self.passedTasks = passedTasks
        self.totalExecutionTime = totalExecutionTime
    }
}

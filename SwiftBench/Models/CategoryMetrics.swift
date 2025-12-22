//
//  CategoryMetrics.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Aggregated metrics for a specific benchmark category.
struct CategoryMetrics: Codable, Hashable, Sendable, Identifiable {
    /// The category these metrics represent.
    let category: BenchmarkCategory

    /// Pass rate (fraction of tasks that passed).
    let passRate: Double

    /// Mean score across all tasks in this category.
    let meanScore: Double

    /// Variance of scores in this category.
    let variance: Double

    /// Number of tasks in this category.
    let taskCount: Int

    /// Number of tasks that passed.
    let passedCount: Int

    /// Mean style score for this category.
    let meanStyleScore: Double

    var id: String { category.id }

    /// Pass rate as a percentage.
    var passRatePercentage: Double {
        passRate * 100
    }

    /// Creates category metrics from a collection of benchmark runs.
    init(
        category: BenchmarkCategory,
        passRate: Double,
        meanScore: Double,
        variance: Double,
        taskCount: Int,
        passedCount: Int,
        meanStyleScore: Double
    ) {
        self.category = category
        self.passRate = passRate
        self.meanScore = meanScore
        self.variance = variance
        self.taskCount = taskCount
        self.passedCount = passedCount
        self.meanStyleScore = meanStyleScore
    }

    /// Calculates metrics from a collection of benchmark runs.
    static func calculate(from runs: [BenchmarkRun], category: BenchmarkCategory) -> CategoryMetrics {
        let categoryRuns = runs.filter { $0.taskCategory == category.rawValue }

        guard !categoryRuns.isEmpty else {
            return CategoryMetrics(
                category: category,
                passRate: 0,
                meanScore: 0,
                variance: 0,
                taskCount: 0,
                passedCount: 0,
                meanStyleScore: 0
            )
        }

        let scores = categoryRuns.map(\.primaryScore)
        let styleScores = categoryRuns.compactMap(\.styleScore)
        let passedCount = categoryRuns.filter(\.passed).count

        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
        let meanStyle = styleScores.isEmpty ? 0 : styleScores.reduce(0, +) / Double(styleScores.count)

        return CategoryMetrics(
            category: category,
            passRate: Double(passedCount) / Double(categoryRuns.count),
            meanScore: mean,
            variance: variance,
            taskCount: categoryRuns.count,
            passedCount: passedCount,
            meanStyleScore: meanStyle
        )
    }
}

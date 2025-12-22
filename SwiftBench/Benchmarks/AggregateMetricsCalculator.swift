//
//  AggregateMetricsCalculator.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Aggregate metrics calculated from multiple benchmark runs.
struct AggregateMetrics: Sendable {
    /// Pass@1: Fraction of tasks passing on first attempt.
    let passAt1: Double

    /// Pass@k: Fraction of tasks passing in any of k attempts.
    let passAtK: Double

    /// The k value used for pass@k.
    let kValue: Int

    /// Mean score across all runs.
    let meanScore: Double

    /// Variance of scores.
    let variance: Double

    /// Standard deviation of scores.
    var standardDeviation: Double {
        sqrt(variance)
    }

    /// Mean style score across all runs.
    let meanStyleScore: Double

    /// Total number of tasks.
    let totalTasks: Int

    /// Number of tasks that passed.
    let passedTasks: Int

    /// Per-category breakdown.
    let categoryMetrics: [CategoryMetrics]
}

/// Calculates aggregate metrics from benchmark runs.
enum AggregateMetricsCalculator {
    /// Calculates pass@k metric.
    ///
    /// pass@k = 1 - C(n-c, k) / C(n, k)
    /// where n = total runs, c = successful runs, k = samples
    ///
    /// - Parameters:
    ///   - totalRuns: Total number of attempts
    ///   - successfulRuns: Number of successful attempts
    ///   - k: Number of samples to consider
    /// - Returns: pass@k probability
    static func passAtK(totalRuns: Int, successfulRuns: Int, k: Int) -> Double {
        guard totalRuns > 0, k > 0, k <= totalRuns else { return 0 }

        // If no successful runs, pass@k is 0
        guard successfulRuns > 0 else { return 0 }

        // If all runs succeeded, pass@k is 1
        guard successfulRuns < totalRuns else { return 1 }

        // Calculate 1 - C(n-c, k) / C(n, k)
        // This is the probability of getting at least one success in k samples
        let n = totalRuns
        let c = successfulRuns

        // C(n-c, k) / C(n, k) = product((n-c-i) / (n-i)) for i in 0..<k
        var ratio = 1.0
        for i in 0..<k {
            ratio *= Double(n - c - i) / Double(n - i)
        }

        return 1.0 - ratio
    }

    /// Calculates mean and variance from a collection of values.
    ///
    /// - Parameter values: Collection of values
    /// - Returns: Tuple of (mean, variance)
    static func statistics<C: Collection>(_ values: C) -> (mean: Double, variance: Double)
    where C.Element == Double {
        guard !values.isEmpty else {
            return (0, 0)
        }

        let count = Double(values.count)
        let mean = values.reduce(0, +) / count

        guard values.count > 1 else {
            return (mean, 0)
        }

        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / count

        return (mean, variance)
    }

    /// Calculates aggregate metrics from a collection of benchmark runs.
    ///
    /// - Parameters:
    ///   - runs: All benchmark runs in the suite
    ///   - suite: The benchmark suite that was run
    ///   - kValue: The k value for pass@k calculation
    /// - Returns: Aggregate metrics
    static func calculate(
        from runs: [BenchmarkRun],
        suite: BenchmarkSuite,
        kValue: Int
    ) -> AggregateMetrics {
        // Group runs by task
        let runsByTask = Dictionary(grouping: runs) { $0.taskID ?? "" }

        // Calculate pass@1 and pass@k per task
        var passAt1Count = 0
        var passAtKCount = 0
        var allScores: [Double] = []
        var allStyleScores: [Double] = []

        for task in suite.tasks {
            let taskRuns = runsByTask[task.id] ?? []
            guard !taskRuns.isEmpty else { continue }

            // Collect scores
            allScores.append(contentsOf: taskRuns.map(\.primaryScore))
            allStyleScores.append(contentsOf: taskRuns.compactMap(\.styleScore))

            // Check pass@1 (first run)
            if let firstRun = taskRuns.first(where: { $0.runIndex == 0 }), firstRun.passed {
                passAt1Count += 1
            }

            // Check pass@k (any of k runs passed)
            let successfulRuns = taskRuns.filter(\.passed).count
            if passAtK(totalRuns: taskRuns.count, successfulRuns: successfulRuns, k: kValue) > 0.5 {
                passAtKCount += 1
            }
        }

        // Calculate overall statistics
        let scoreStats = statistics(allScores)
        let styleStats = statistics(allStyleScores)

        // Calculate per-category metrics
        let categoryMetrics = BenchmarkCategory.allCases.map { category in
            CategoryMetrics.calculate(from: runs, category: category)
        }.filter { $0.taskCount > 0 }

        return AggregateMetrics(
            passAt1: Double(passAt1Count) / Double(max(suite.taskCount, 1)),
            passAtK: Double(passAtKCount) / Double(max(suite.taskCount, 1)),
            kValue: kValue,
            meanScore: scoreStats.mean,
            variance: scoreStats.variance,
            meanStyleScore: styleStats.mean,
            totalTasks: suite.taskCount,
            passedTasks: passAt1Count,
            categoryMetrics: categoryMetrics
        )
    }

    /// Calculates metrics for a single task with multiple runs.
    ///
    /// - Parameters:
    ///   - runs: Runs for a single task
    ///   - kValue: The k value for pass@k
    /// - Returns: Tuple of (pass@1, pass@k, mean score, variance)
    static func calculateTaskMetrics(
        runs: [BenchmarkRun],
        kValue: Int
    ) -> (passAt1: Bool, passAtK: Double, meanScore: Double, variance: Double) {
        guard !runs.isEmpty else {
            return (false, 0, 0, 0)
        }

        // Sort by run index to find first run
        let sortedRuns = runs.sorted { ($0.runIndex ?? 0) < ($1.runIndex ?? 0) }

        let passAt1 = sortedRuns.first?.passed ?? false
        let successfulRuns = runs.filter(\.passed).count
        let passAtKValue = passAtK(totalRuns: runs.count, successfulRuns: successfulRuns, k: kValue)

        let scores = runs.map(\.primaryScore)
        let stats = statistics(scores)

        return (passAt1, passAtKValue, stats.mean, stats.variance)
    }
}

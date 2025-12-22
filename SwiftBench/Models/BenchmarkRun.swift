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
    // MARK: - Identity

    var id = UUID()
    var createdAt = Date.now

    // MARK: - Benchmark Info

    var benchmarkID = ""
    var benchmarkTitle = ""

    // MARK: - Task Info (for suite runs)

    /// The task ID within a suite (nil for legacy single-benchmark runs).
    var taskID: String?

    /// The category of the task.
    var taskCategory: String?

    // MARK: - Model Info

    var modelIdentifier = ""
    var provider: String?

    // MARK: - Input/Output

    var prompt = ""
    var response = ""

    // MARK: - Similarity Score (legacy/fallback)

    /// The text-similarity-based score (0-100).
    var score = 0.0

    // MARK: - Execution Results (macOS only)

    /// Whether the generated code compiled successfully.
    var compilationSucceeded: Bool?

    /// Compilation error messages if compilation failed.
    var compilationErrors: String?

    /// Full compilation output (stdout + stderr).
    var compilationOutput: String?

    /// Number of tests that passed.
    var testsPassed: Int?

    /// Total number of tests executed.
    var testsTotal: Int?

    /// Full test output (stdout + stderr).
    var testOutput: String?

    /// Time taken for compilation and test execution.
    var executionTimeSeconds: Double?

    // MARK: - Style Score

    /// The AST-based style/modernity score (0-100).
    var styleScore: Double?

    /// List of style rule violations (JSON-encoded array).
    var styleViolationsJSON: String?

    // MARK: - Run Configuration

    /// Temperature used for this run.
    var temperature: Double?

    /// Run index for pass@k (0-based).
    var runIndex: Int?

    // MARK: - Token Usage

    var tokenPrompt = 0
    var tokenCompletion = 0
    var tokenTotal = 0

    // MARK: - Computed Properties

    /// Style violations decoded from JSON.
    var styleViolations: [String] {
        get {
            guard let json = styleViolationsJSON,
                  let data = json.data(using: .utf8),
                  let violations = try? JSONDecoder().decode([String].self, from: data)
            else {
                return []
            }
            return violations
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                styleViolationsJSON = json
            } else {
                styleViolationsJSON = nil
            }
        }
    }

    /// The primary score based on execution results (test pass rate).
    /// Falls back to similarity score if execution wasn't performed.
    /// Provides partial scoring for compilation failures based on style score.
    var primaryScore: Double {
        // If tests ran successfully, use test pass rate
        if let passed = testsPassed, let total = testsTotal, total > 0 {
            return Double(passed) / Double(total) * 100
        }

        // If compilation failed but we have a style score, provide partial credit
        if let compiled = compilationSucceeded, !compiled {
            if let style = styleScore {
                // Give 20% of style score as partial credit for structural validity
                return style * 0.2
            }
            // No execution results at all - return similarity score
            return score
        }

        // Default fallback
        return score
    }

    /// Whether this run has execution results.
    var hasExecutionResults: Bool {
        compilationSucceeded != nil
    }

    /// Whether the run passed (compiled and all tests passed).
    var passed: Bool {
        guard let compiled = compilationSucceeded, compiled else { return false }
        guard let passed = testsPassed, let total = testsTotal else { return false }
        return passed == total
    }

    /// Test pass rate as a fraction (0.0 to 1.0).
    var testPassRate: Double {
        guard let passed = testsPassed, let total = testsTotal, total > 0 else {
            return 0
        }
        return Double(passed) / Double(total)
    }

    // MARK: - Initializers

    /// Creates a legacy benchmark run (similarity-based only).
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

    /// Creates a full benchmark run with execution results.
    init(
        benchmarkID: String,
        benchmarkTitle: String,
        taskID: String?,
        taskCategory: String?,
        modelIdentifier: String,
        provider: String?,
        prompt: String,
        response: String,
        score: Double,
        compilationSucceeded: Bool?,
        compilationErrors: String?,
        compilationOutput: String?,
        testsPassed: Int?,
        testsTotal: Int?,
        testOutput: String?,
        executionTimeSeconds: Double?,
        styleScore: Double?,
        styleViolations: [String],
        temperature: Double?,
        runIndex: Int?,
        tokenPrompt: Int,
        tokenCompletion: Int,
        tokenTotal: Int
    ) {
        self.benchmarkID = benchmarkID
        self.benchmarkTitle = benchmarkTitle
        self.taskID = taskID
        self.taskCategory = taskCategory
        self.modelIdentifier = modelIdentifier
        self.provider = provider
        self.prompt = prompt
        self.response = response
        self.score = score
        self.compilationSucceeded = compilationSucceeded
        self.compilationErrors = compilationErrors
        self.compilationOutput = compilationOutput
        self.testsPassed = testsPassed
        self.testsTotal = testsTotal
        self.testOutput = testOutput
        self.executionTimeSeconds = executionTimeSeconds
        self.styleScore = styleScore
        self.styleViolations = styleViolations
        self.temperature = temperature
        self.runIndex = runIndex
        self.tokenPrompt = tokenPrompt
        self.tokenCompletion = tokenCompletion
        self.tokenTotal = tokenTotal
    }
}

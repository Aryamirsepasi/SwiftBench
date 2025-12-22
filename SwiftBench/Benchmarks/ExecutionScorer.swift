//
//  ExecutionScorer.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Score breakdown from execution-based evaluation.
struct ExecutionScore: Sendable {
    /// Score for successful compilation (0 or 100).
    let compilationScore: Double

    /// Score for passing tests (0-100).
    let testScore: Double

    /// Combined primary score (0-100).
    let primaryScore: Double

    /// Style/modernity score (0-100), nil if not evaluated.
    let styleScore: Double?

    /// Whether all tests passed.
    let passed: Bool
}

/// Calculates scores from execution results.
///
/// The primary score is based on compilation and test pass rate:
/// - Compilation failure: 0 points
/// - Compilation success: 30 points base + 70 points * test pass rate
enum ExecutionScorer {
    /// Weight for compilation success in the primary score.
    static let compilationWeight = 0.3

    /// Weight for test pass rate in the primary score.
    static let testWeight = 0.7

    /// Calculates scores from an execution result.
    ///
    /// - Parameter result: The execution result to score
    /// - Returns: Calculated scores
    static func score(result: ExecutionResult) -> ExecutionScore {
        let compilationScore = result.compilationSucceeded ? 100.0 : 0.0
        let testScore = result.testPassRate * 100

        // If compilation failed, primary score is 0
        let primaryScore: Double
        if result.compilationSucceeded {
            primaryScore = (compilationWeight * 100) + (testWeight * testScore)
        } else {
            primaryScore = 0
        }

        return ExecutionScore(
            compilationScore: compilationScore,
            testScore: testScore,
            primaryScore: primaryScore,
            styleScore: result.styleScore,
            passed: result.allTestsPassed
        )
    }

    #if os(macOS)
    /// Convenience method that takes ExecutionResult directly.
    static func score(from result: ExecutionResult) -> ExecutionScore {
        score(result: result)
    }
    #endif
}

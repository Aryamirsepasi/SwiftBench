//
//  TestExecutionService.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

#if os(macOS)

import Foundation

/// Result of executing generated code against a benchmark task.
struct ExecutionResult: Sendable {
    /// Whether the generated code compiled successfully.
    let compilationSucceeded: Bool

    /// Compilation error messages if compilation failed.
    let compilationErrors: String?

    /// Full compilation output.
    let compilationOutput: String

    /// Number of tests that passed.
    let testsPassed: Int

    /// Total number of tests executed.
    let testsTotal: Int

    /// Full test output.
    let testOutput: String

    /// Total execution time in seconds.
    let executionTime: TimeInterval

    /// Style score from AST analysis (0-100).
    let styleScore: Double?

    /// List of style rule violations.
    let styleViolations: [String]

    /// Test pass rate as a fraction (0.0 to 1.0).
    var testPassRate: Double {
        testsTotal > 0 ? Double(testsPassed) / Double(testsTotal) : 0
    }

    /// Whether all tests passed.
    var allTestsPassed: Bool {
        compilationSucceeded && testsPassed == testsTotal && testsTotal > 0
    }

    /// Primary score (0-100) based on compilation and test results.
    var primaryScore: Double {
        guard compilationSucceeded else { return 0 }
        return testPassRate * 100
    }
}

/// Errors that can occur during test execution.
enum TestExecutionError: Error, LocalizedError {
    case packageCreationFailed(Error)
    case buildFailed(ProcessResult)
    case testFailed(ProcessResult)
    case cancelled

    var errorDescription: String? {
        switch self {
        case let .packageCreationFailed(error):
            "Failed to create test package: \(error.localizedDescription)"
        case let .buildFailed(result):
            "Build failed: \(result.stderr)"
        case let .testFailed(result):
            "Tests failed: \(result.stderr)"
        case .cancelled:
            "Execution was cancelled"
        }
    }
}

/// Service for executing generated code against benchmark tasks.
///
/// This service:
/// 1. Creates a temporary SwiftPM package with the generated code
/// 2. Runs `swift build` to check compilation
/// 3. Runs `swift test` to execute tests
/// 4. Parses results and calculates scores
/// 5. Cleans up the temporary package
@MainActor
@Observable
final class TestExecutionService {
    /// Current execution phase.
    private(set) var currentPhase: ExecutionPhase = .idle

    /// Whether an execution is in progress.
    private(set) var isExecuting = false

    /// Progress message for the current phase.
    var progressMessage: String {
        switch currentPhase {
        case .idle:
            "Ready"
        case .creatingPackage:
            "Creating test package..."
        case .compiling:
            "Compiling generated code..."
        case .runningTests:
            "Running tests..."
        case .parsingResults:
            "Parsing results..."
        case .cleaningUp:
            "Cleaning up..."
        }
    }

    /// Execution phases.
    enum ExecutionPhase: Sendable {
        case idle
        case creatingPackage
        case compiling
        case runningTests
        case parsingResults
        case cleaningUp
    }

    /// Executes generated code against a benchmark task.
    ///
    /// - Parameters:
    ///   - generatedCode: The LLM-generated code to test
    ///   - task: The benchmark task with test definitions
    ///   - buildTimeout: Maximum time for compilation
    ///   - testTimeout: Maximum time for test execution
    /// - Returns: The execution result with scores and output
    func execute(
        generatedCode: String,
        task: BenchmarkTask,
        buildTimeout: TimeInterval = 120,
        testTimeout: TimeInterval = 180
    ) async throws -> ExecutionResult {
        guard !isExecuting else {
            throw TestExecutionError.cancelled
        }

        isExecuting = true
        defer {
            isExecuting = false
            currentPhase = .idle
        }

        var packageDir: URL?

        do {
            print("[DEBUG] ===== Starting test execution for task: \(task.title) =====")
            print("[DEBUG] Generated code length: \(generatedCode.count) characters")

            // Phase 1: Create package
            currentPhase = .creatingPackage
            packageDir = try PackageGenerator.createPackage(
                generatedCode: generatedCode,
                task: task
            )

            print("[DEBUG] Created package at: \(packageDir?.path ?? "unknown")")
            print("[DEBUG] Task has tests: \(task.hasTests)")
            print("[DEBUG] Task uses IO pairs: \(task.usesIOTesting)")
            print("[DEBUG] Task uses XCTest: \(task.usesXCTest)")

            // Phase 2: Build
            currentPhase = .compiling
            print("[DEBUG] Starting compilation...")
            let buildResult = try await ProcessRunner.swiftBuild(
                in: packageDir!,
                timeout: buildTimeout
            )

            print("[DEBUG] Build completed in \(buildResult.duration)s")
            print("[DEBUG] Build exit code: \(buildResult.exitCode)")
            print("[DEBUG] Build succeeded: \(buildResult.succeeded)")

            if !buildResult.succeeded {
                print("[DEBUG] Build failed. Stderr (first 1000 chars):")
                print(String(buildResult.stderr.prefix(1000)))
                print("[DEBUG] Build stdout (first 500 chars):")
                print(String(buildResult.stdout.prefix(500)))
            }

            // If build failed, return early
            guard buildResult.succeeded else {
                currentPhase = .cleaningUp
                try? PackageGenerator.cleanup(packageDir: packageDir!)

                print("[DEBUG] Returning early due to build failure")

                return ExecutionResult(
                    compilationSucceeded: false,
                    compilationErrors: buildResult.stderr,
                    compilationOutput: buildResult.combinedOutput,
                    testsPassed: 0,
                    testsTotal: 0,
                    testOutput: "",
                    executionTime: buildResult.duration,
                    styleScore: nil,
                    styleViolations: []
                )
            }

            // Phase 3: Run tests
            currentPhase = .runningTests
            print("[DEBUG] Starting test execution...")
            let testResult = try await ProcessRunner.swiftTest(
                in: packageDir!,
                timeout: testTimeout
            )

            print("[DEBUG] Test completed in \(testResult.duration)s")
            print("[DEBUG] Test exit code: \(testResult.exitCode)")
            print("[DEBUG] Test succeeded: \(testResult.succeeded)")
            print("[DEBUG] Test stdout (first 1000 chars):")
            print(String(testResult.stdout.prefix(1000)))
            print("[DEBUG] Test stderr (first 1000 chars):")
            print(String(testResult.stderr.prefix(1000)))

            // Phase 4: Parse results
            currentPhase = .parsingResults
            let parsedResult = TestResultParser.parse(testOutput: testResult.combinedOutput)
            let styleResult = parseStyleResults(from: testResult.combinedOutput, task: task)

            print("[DEBUG] Style score: \(styleResult.score ?? 0)")
            print("[DEBUG] Style violations: \(styleResult.violations)")

            // Phase 5: Cleanup
            currentPhase = .cleaningUp
            try? PackageGenerator.cleanup(packageDir: packageDir!)

            print("[DEBUG] ===== Test execution completed =====")

            return ExecutionResult(
                compilationSucceeded: true,
                compilationErrors: nil,
                compilationOutput: buildResult.combinedOutput,
                testsPassed: parsedResult.passed,
                testsTotal: parsedResult.total,
                testOutput: testResult.combinedOutput,
                executionTime: buildResult.duration + testResult.duration,
                styleScore: styleResult.score,
                styleViolations: styleResult.violations
            )

        } catch {
            // Cleanup on error
            if let dir = packageDir {
                try? PackageGenerator.cleanup(packageDir: dir)
            }
            print("[ERROR] Test execution error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Cancels the current execution.
    func cancel() {
        // Note: Full cancellation would require tracking the running process
        // For now, this just prevents new executions
        currentPhase = .idle
        isExecuting = false
    }

    // MARK: - Private Helpers

    private func parseStyleResults(from output: String, task: BenchmarkTask) -> (score: Double?, violations: [String]) {
        var violations: [String] = []

        // Look for style test failures in the output
        for ruleID in task.styleRules {
            if let rule = StyleRule.rule(for: ruleID) {
                // Check if this rule's test failed
                let testName = "test" + ruleID
                    .replacing("-", with: "")
                    .split(separator: "-")
                    .map { $0.capitalized }
                    .joined()

                if output.contains("\(testName)") && output.contains("failed") {
                    violations.append(rule.name)
                }
            }
        }

        // Calculate style score
        guard !task.styleRules.isEmpty else {
            return (nil, [])
        }

        let passedRules = task.styleRules.count - violations.count
        let score = Double(passedRules) / Double(task.styleRules.count) * 100

        return (score, violations)
    }
}

#endif

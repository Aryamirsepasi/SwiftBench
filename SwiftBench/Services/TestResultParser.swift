//
//  TestResultParser.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Parsed result from swift test output.
struct ParsedTestResult: Sendable {
    /// Number of tests that passed.
    let passed: Int

    /// Number of tests that failed.
    let failed: Int

    /// Total number of tests executed.
    let total: Int

    /// Individual test failure messages.
    let failureMessages: [String]

    /// Test pass rate as a fraction.
    var passRate: Double {
        total > 0 ? Double(passed) / Double(total) : 0
    }

    /// Whether all tests passed.
    var allPassed: Bool {
        passed == total && total > 0
    }
}

/// Parses swift test output to extract test results.
enum TestResultParser {
    /// Parses the output from `swift test` to extract pass/fail counts.
    ///
    /// - Parameter testOutput: The combined stdout/stderr from swift test
    /// - Returns: Parsed test results
    static func parse(testOutput: String) -> ParsedTestResult {
        var passed = 0
        var failed = 0
        var failureMessages: [String] = []

        let lines = testOutput.split(separator: "\n", omittingEmptySubsequences: false)

        // Look for the summary line: "Test Suite 'All tests' passed at..."
        // or individual test results
        for line in lines {
            let lineStr = String(line)

            // Match individual test results
            // Format: "Test Case '-[TestTarget.TestClass testMethod]' passed (0.001 seconds)."
            // Or: "Test Case 'TestClass.testMethod' passed (0.001 seconds)."
            if lineStr.contains("Test Case") {
                if lineStr.contains("passed") {
                    passed += 1
                } else if lineStr.contains("failed") {
                    failed += 1
                    // Extract failure message
                    if let message = extractFailureMessage(from: lineStr) {
                        failureMessages.append(message)
                    }
                }
            }

            // Also check for XCTest assertion failures
            // Format: "/path/to/file.swift:42: error: -[TestTarget.TestClass testMethod] : XCTAssertTrue failed"
            if lineStr.contains("error:") && lineStr.contains("XCT") {
                if let message = lineStr.split(separator: ":").last {
                    let trimmed = String(message).trimmingCharacters(in: .whitespaces)
                    if !failureMessages.contains(trimmed) {
                        failureMessages.append(trimmed)
                    }
                }
            }
        }

        // If we didn't find individual results, try parsing the summary
        if passed == 0 && failed == 0 {
            // Look for: "Executed 5 tests, with 2 failures (0 unexpected) in 0.123 (0.456) seconds"
            for line in lines {
                let lineStr = String(line)
                if lineStr.contains("Executed") && lineStr.contains("tests") {
                    if let result = parseSummaryLine(lineStr) {
                        return result
                    }
                }
            }

            // Also try to parse from Test Suite summary (XCTest 5.x+)
            // Format: "Test Suite 'All tests' passed at 12/12/23 16:23:45"
            // Or: "Test Suite 'All tests' failed at 12/12/23 16:23:45"
            for line in lines {
                let lineStr = String(line)
                if lineStr.contains("Test Suite") && lineStr.contains("All tests") {
                    if lineStr.contains("passed") {
                        // When test suite passed, look for test count in previous lines
                        // Pattern: "Test Suite 'GeneratedCodeTests' passed at..."
                        for offset in 1...min(10, lines.count - 1) {
                            let lineIndex = lines.firstIndex(of: line)
                            if lineIndex == nil { break }
                            let offsetIndex = lines.index(lineIndex!, offsetBy: -offset)
                            if offsetIndex >= lines.startIndex {
                                let nearbyLine = String(lines[offsetIndex])
                                // Look for test counts like "Executed X tests" or just "X tests"
                                if let result = parseSummaryLine(nearbyLine) {
                                    return result
                                }
                            }
                        }
                    }
                }
            }
        }

        print("[DEBUG] TestResultParser parsed:")
        print("  - Passed: \(passed)")
        print("  - Failed: \(failed)")
        print("  - Total: \(passed + failed)")
        print("  - Failure messages: \(failureMessages)")
        if testOutput.count > 0 {
            print("[DEBUG] Raw test output (first 1000 chars):")
            print(String(testOutput.prefix(1000)))
        }

        return ParsedTestResult(
            passed: passed,
            failed: failed,
            total: passed + failed,
            failureMessages: failureMessages
        )
    }

    // MARK: - Private Helpers

    private static func extractFailureMessage(from line: String) -> String? {
        // Extract the test name from the line
        if let start = line.firstIndex(of: "'"),
           let end = line[line.index(after: start)...].firstIndex(of: "'") {
            return String(line[line.index(after: start)..<end])
        }
        return nil
    }

    private static func parseSummaryLine(_ line: String) -> ParsedTestResult? {
        // Parse: "Executed 5 tests, with 2 failures (0 unexpected) in 0.123 (0.456) seconds"
        let pattern = #"Executed (\d+) tests?, with (\d+) failures?"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: line,
                  range: NSRange(line.startIndex..., in: line)
              )
        else {
            return nil
        }

        guard let totalRange = Range(match.range(at: 1), in: line),
              let failedRange = Range(match.range(at: 2), in: line),
              let total = Int(line[totalRange]),
              let failed = Int(line[failedRange])
        else {
            return nil
        }

        let passed = total - failed

        return ParsedTestResult(
            passed: passed,
            failed: failed,
            total: total,
            failureMessages: []
        )
    }
}

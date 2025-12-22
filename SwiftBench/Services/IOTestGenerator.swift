//
//  IOTestGenerator.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Generates XCTest code from input/output pairs.
///
/// For algorithm tasks with defined IO pairs, this generates a test file
/// that calls the expected function and verifies output.
enum IOTestGenerator {
    /// Generates XCTest code for a benchmark task with IO pairs.
    ///
    /// - Parameter task: The benchmark task with inputOutputPairs
    /// - Returns: Swift test file content
    static func generateTestCode(for task: BenchmarkTask) -> String {
        guard let pairs = task.inputOutputPairs, !pairs.isEmpty else {
            return fallbackTestCode()
        }

        guard let functionName = task.functionName else {
            return fallbackTestCode()
        }

        var testMethods = ""

        for (index, pair) in pairs.enumerated() {
            let testName = "testCase\(index)"
            let description = pair.description ?? "Input: \(pair.input), Expected: \(pair.expectedOutput)"
            let functionCall = generateFunctionCall(functionName: functionName, input: pair.input)
            let assertion = generateAssertion(expectedOutput: pair.expectedOutput)

            testMethods += """

                func \(testName)() {
                    // \(description)
                    let result = \(functionCall)
                    \(assertion)
                }

            """
        }

        return """
        import XCTest
        @testable import GeneratedCode

        final class IOTests: XCTestCase {
        \(testMethods)
        }
        """
    }

    /// Generates a more sophisticated test for functions that return complex types.
    static func generateTypedTestCode(
        for task: BenchmarkTask,
        returnType: String
    ) -> String {
        guard let pairs = task.inputOutputPairs, !pairs.isEmpty else {
            return fallbackTestCode()
        }

        guard let functionName = task.functionName else {
            return fallbackTestCode()
        }

        var testMethods = ""

        for (index, pair) in pairs.enumerated() {
            let testName = "testCase\(index)"
            let description = pair.description ?? "Input: \(pair.input), Expected: \(pair.expectedOutput)"

            testMethods += """

                func \(testName)() {
                    // \(description)
                    let result: \(returnType) = \(functionName)(\(pair.input))
                    let expected: \(returnType) = \(pair.expectedOutput)
                    XCTAssertEqual(result, expected)
                }

            """
        }

        return """
        import XCTest
        @testable import GeneratedCode

        final class IOTests: XCTestCase {
        \(testMethods)
        }
        """
    }

    /// Generates test code for array-returning functions.
    static func generateArrayTestCode(
        for task: BenchmarkTask,
        elementType: String
    ) -> String {
        guard let pairs = task.inputOutputPairs, !pairs.isEmpty else {
            return fallbackTestCode()
        }

        guard let functionName = task.functionName else {
            return fallbackTestCode()
        }

        var testMethods = ""

        for (index, pair) in pairs.enumerated() {
            let testName = "testCase\(index)"
            let description = pair.description ?? "Input: \(pair.input), Expected: \(pair.expectedOutput)"

            testMethods += """

                func \(testName)() {
                    // \(description)
                    let result: [\(elementType)] = \(functionName)(\(pair.input))
                    let expected: [\(elementType)] = \(pair.expectedOutput)
                    XCTAssertEqual(result, expected)
                }

            """
        }

        return """
        import XCTest
        @testable import GeneratedCode

        final class IOTests: XCTestCase {
        \(testMethods)
        }
        """
    }

    // MARK: - Private Helpers

    private static func fallbackTestCode() -> String {
        """
        import XCTest
        @testable import GeneratedCode

        final class GeneratedCodeTests: XCTestCase {
            func testCodeCompiles() {
                // This test passes if the code compiles successfully
                XCTAssertTrue(true, "Generated code compiled successfully")
            }
        }
        """
    }

    /// Generates a proper function call string from the input.
    private static func generateFunctionCall(functionName: String, input: String) -> String {
        // The input string should already be valid Swift code for the function call
        // For example: "0", "[1, 2, 3], target: 5", etc.
        return "\(functionName)(\(input))"
    }

    /// Generates a type-safe assertion for the expected output.
    private static func generateAssertion(expectedOutput: String) -> String {
        let trimmed = expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle different output types
        if trimmed.hasPrefix("Optional(") && trimmed.hasSuffix(")") {
            // Optional type - unwrap and compare
            let innerValue = String(trimmed.dropFirst("Optional(".count).dropLast())
            let escapedInner = escapeSwiftLiteral(innerValue)
            return "XCTAssertEqual(String(describing: result), \"Optional(\(escapedInner))\")"
        } else if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            // Array type - use string comparison for arrays
            let escaped = escapeSwiftLiteral(trimmed)
            return "XCTAssertEqual(String(describing: result), \"\(escaped)\")"
        } else if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            // String type - remove quotes for direct comparison
            let innerValue = String(trimmed.dropFirst().dropLast())
            let escaped = escapeSwiftLiteral(innerValue)
            return "XCTAssertEqual(result, \"\(escaped)\")"
        } else if trimmed == "true" || trimmed == "false" {
            // Boolean type
            return "XCTAssertEqual(result, \(trimmed))"
        } else if Int(trimmed) != nil {
            // Integer type
            return "XCTAssertEqual(result, \(trimmed))"
        } else if Double(trimmed) != nil {
            // Double type
            return "XCTAssertEqual(result, \(trimmed))"
        } else {
            // Fallback to string description comparison
            let escaped = escapeSwiftLiteral(trimmed)
            return "XCTAssertEqual(String(describing: result), \"\(escaped)\")"
        }
    }

    /// Escapes a Swift literal for use in a string literal.
    private static func escapeSwiftLiteral(_ string: String) -> String {
        string
            .replacing("\\", with: "\\\\")
            .replacing("\"", with: "\\\"")
            .replacing("\n", with: "\\n")
            .replacing("\t", with: "\\t")
            .replacing("\r", with: "\\r")
    }

    private static func escapeString(_ string: String) -> String {
        string
            .replacing("\\", with: "\\\\")
            .replacing("\"", with: "\\\"")
            .replacing("\n", with: "\\n")
            .replacing("\t", with: "\\t")
    }
}

//
//  BenchmarkTask.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// A single benchmark task that tests a specific coding skill.
///
/// Each task includes a prompt for the LLM, test definitions to verify correctness,
/// and optional style rules for AST-based analysis.
struct BenchmarkTask: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for this task.
    let id: String

    /// Human-readable title for the task.
    let title: String

    /// Category this task belongs to.
    let category: BenchmarkCategory

    /// Difficulty level of this task.
    let difficulty: TaskDifficulty

    /// The prompt to send to the LLM.
    let prompt: String

    /// XCTest file content for behavioral tests (optional).
    ///
    /// If provided, this test code will be compiled and run against the generated code.
    /// The test file should import `@testable import GeneratedCode`.
    let testCode: String?

    /// Input/output pairs for algorithm tasks (optional).
    ///
    /// For simple algorithm tasks, these pairs define expected behavior.
    /// The system will generate XCTest assertions from these pairs.
    let inputOutputPairs: [IOPair]?

    /// Reference implementation for style scoring comparison (optional).
    ///
    /// Used to compare the generated code's style and structure.
    let referenceCode: String?

    /// Style rules to check using SwiftSyntax AST analysis.
    ///
    /// These identifiers map to predefined style checks that verify
    /// modern Swift/SwiftUI patterns in the actual code (not comments/strings).
    let styleRules: [StyleRuleIdentifier]

    /// The name of the function to test when using input/output pairs.
    ///
    /// Required when `inputOutputPairs` is provided.
    let functionName: String?

    /// Expected function signature for validation (optional).
    ///
    /// Used to verify the generated code has the correct function signature.
    let expectedSignature: String?

    /// Creates a new benchmark task.
    init(
        id: String,
        title: String,
        category: BenchmarkCategory,
        difficulty: TaskDifficulty,
        prompt: String,
        testCode: String? = nil,
        inputOutputPairs: [IOPair]? = nil,
        referenceCode: String? = nil,
        styleRules: [StyleRuleIdentifier] = [],
        functionName: String? = nil,
        expectedSignature: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.difficulty = difficulty
        self.prompt = prompt
        self.testCode = testCode
        self.inputOutputPairs = inputOutputPairs
        self.referenceCode = referenceCode
        self.styleRules = styleRules
        self.functionName = functionName
        self.expectedSignature = expectedSignature
    }

    /// Whether this task has executable tests.
    var hasTests: Bool {
        testCode != nil || inputOutputPairs != nil
    }

    /// Whether this task uses input/output pair testing.
    var usesIOTesting: Bool {
        inputOutputPairs != nil && !(inputOutputPairs?.isEmpty ?? true)
    }

    /// Whether this task uses XCTest behavioral testing.
    var usesXCTest: Bool {
        testCode != nil && !(testCode?.isEmpty ?? true)
    }
}

// MARK: - IOPair

/// An input/output pair for testing algorithm correctness.
struct IOPair: Hashable, Codable, Sendable {
    /// The input value(s) as a string representation.
    ///
    /// For multiple parameters, use comma-separated values.
    let input: String

    /// The expected output value as a string representation.
    let expectedOutput: String

    /// Optional description of what this test case verifies.
    let description: String?

    init(input: String, expectedOutput: String, description: String? = nil) {
        self.input = input
        self.expectedOutput = expectedOutput
        self.description = description
    }
}

// MARK: - StyleRuleIdentifier

/// Type alias for style rule identifiers.
///
/// These map to predefined SwiftSyntax-based style checks.
typealias StyleRuleIdentifier = String

/// Common style rule identifiers for SwiftSyntax analysis.
enum StyleRules {
    // MARK: Modern APIs
    static let useObservable = "use-observable"
    static let useMainActor = "use-main-actor"
    static let useNavigationStack = "use-navigation-stack"
    static let useTabAPI = "use-tab-api"
    static let useAsyncAwait = "use-async-await"
    static let useSendable = "use-sendable"
    static let useForegroundStyle = "use-foreground-style"
    static let useClipShapeRect = "use-clip-shape-rect"
    static let useScaledMetric = "use-scaled-metric"
    static let useScrollIndicators = "use-scroll-indicators"
    static let useContentUnavailable = "use-content-unavailable"

    // MARK: SwiftData
    static let useSwiftDataModel = "use-swiftdata-model"
    static let useQuery = "use-query"

    // MARK: Accessibility
    static let useAccessibilityLabel = "use-accessibility-label"
    static let useAccessibilityValue = "use-accessibility-value"

    // MARK: Anti-patterns
    static let noDispatchQueue = "no-dispatch-queue"
    static let noObservableObject = "no-observable-object"
    static let noPublished = "no-published"
    static let noForegroundColor = "no-foreground-color"
    static let noCornerRadius = "no-corner-radius"
    static let noTabItem = "no-tab-item"
    static let noNavigationView = "no-navigation-view"
    static let noForceUnwrap = "no-force-unwrap"
    static let noForceTry = "no-force-try"
    static let noUIScreenMain = "no-uiscreen-main"

    // MARK: Code Quality
    static let hasDocumentation = "has-documentation"
    static let hasMarkComments = "has-mark-comments"
    static let usesPrivateAccess = "uses-private-access"
    static let usesGuardStatements = "uses-guard-statements"
}

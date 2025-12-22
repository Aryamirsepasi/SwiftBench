//
//  PackageGenerator.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

#if os(macOS)

import Foundation

/// Errors that can occur during package generation.
enum PackageGeneratorError: Error, LocalizedError {
    case failedToCreateDirectory(Error)
    case failedToWriteFile(String, Error)
    case invalidTask

    var errorDescription: String? {
        switch self {
        case let .failedToCreateDirectory(error):
            "Failed to create package directory: \(error.localizedDescription)"
        case let .failedToWriteFile(file, error):
            "Failed to write \(file): \(error.localizedDescription)"
        case .invalidTask:
            "Task has no test definitions"
        }
    }
}

/// Generates temporary SwiftPM packages for testing generated code.
///
/// Creates a package structure with:
/// - Package.swift (with SwiftSyntax dependency for style analysis)
/// - Sources/GeneratedCode/GeneratedCode.swift (the LLM output)
/// - Tests/GeneratedCodeTests/GeneratedCodeTests.swift (behavioral tests)
/// - Tests/GeneratedCodeTests/StyleAnalysisTests.swift (AST-based style checks)
enum PackageGenerator {
    /// Base directory for temporary packages.
    ///
    /// Uses the system temporary directory, which is accessible within the app sandbox.
    /// Note: Running `swift build`/`swift test` requires the app to be non-sandboxed
    /// or to use a helper tool. For development, consider disabling sandboxing in
    /// the Xcode project settings.
    static var tempDirectory: URL {
        FileManager.default.temporaryDirectory
            .appending(path: "SwiftBench", directoryHint: .isDirectory)
    }

    /// Creates a temporary SwiftPM package for testing.
    ///
    /// - Parameters:
    ///   - generatedCode: The LLM-generated code to test
    ///   - task: The benchmark task with test definitions
    /// - Returns: URL of the created package directory
    static func createPackage(
        generatedCode: String,
        task: BenchmarkTask
    ) throws -> URL {
        // Create unique directory for this package
        let packageID = UUID().uuidString
        let packageDir = tempDirectory.appending(path: "Benchmark_\(packageID)", directoryHint: .isDirectory)

        do {
            try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true)
        } catch {
            throw PackageGeneratorError.failedToCreateDirectory(error)
        }

        // Create directory structure
        let sourcesDir = packageDir.appending(path: "Sources/GeneratedCode", directoryHint: .isDirectory)
        let testsDir = packageDir.appending(path: "Tests/GeneratedCodeTests", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: testsDir, withIntermediateDirectories: true)

        // Write Package.swift
        let packageManifest = generatePackageManifest(includeSwiftSyntax: !task.styleRules.isEmpty)
        try writeFile(packageManifest, to: packageDir.appending(path: "Package.swift"))

        // Write generated code
        try writeFile(generatedCode, to: sourcesDir.appending(path: "GeneratedCode.swift"))

        // Write test files
        let testCode = generateTestCode(for: task)
        try writeFile(testCode, to: testsDir.appending(path: "GeneratedCodeTests.swift"))

        // Write style analysis tests if style rules are specified
        if !task.styleRules.isEmpty {
            let styleTests = generateStyleAnalysisTests(for: task)
            try writeFile(styleTests, to: testsDir.appending(path: "StyleAnalysisTests.swift"))
        }

        return packageDir
    }

    /// Cleans up a package directory.
    static func cleanup(packageDir: URL) throws {
        try FileManager.default.removeItem(at: packageDir)
    }

    /// Cleans up all temporary packages.
    static func cleanupAll() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path()) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
    }

    // MARK: - Private Helpers

    private static func writeFile(_ content: String, to url: URL) throws {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw PackageGeneratorError.failedToWriteFile(url.lastPathComponent, error)
        }
    }

    // MARK: - Package.swift Generation

    private static func generatePackageManifest(includeSwiftSyntax: Bool) -> String {
        if includeSwiftSyntax {
            return """
            // swift-tools-version: 6.0
            import PackageDescription

            let package = Package(
                name: "BenchmarkEvaluation",
                platforms: [.macOS(.v15)],
                dependencies: [
                    .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0")
                ],
                targets: [
                    .target(name: "GeneratedCode"),
                    .testTarget(
                        name: "GeneratedCodeTests",
                        dependencies: [
                            "GeneratedCode",
                            .product(name: "SwiftSyntax", package: "swift-syntax"),
                            .product(name: "SwiftParser", package: "swift-syntax"),
                        ]
                    )
                ]
            )
            """
        } else {
            return """
            // swift-tools-version: 6.0
            import PackageDescription

            let package = Package(
                name: "BenchmarkEvaluation",
                platforms: [.macOS(.v15)],
                targets: [
                    .target(name: "GeneratedCode"),
                    .testTarget(
                        name: "GeneratedCodeTests",
                        dependencies: ["GeneratedCode"]
                    )
                ]
            )
            """
        }
    }

    // MARK: - Test Code Generation

    private static func generateTestCode(for task: BenchmarkTask) -> String {
        // If task has custom XCTest code, use it
        if let testCode = task.testCode, !testCode.isEmpty {
            return testCode
        }

        // If task has IO pairs, generate tests from them
        if let pairs = task.inputOutputPairs, !pairs.isEmpty {
            return IOTestGenerator.generateTestCode(for: task)
        }

        // Fallback: basic compilation test
        return """
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

    // MARK: - Style Analysis Tests

    private static func generateStyleAnalysisTests(for task: BenchmarkTask) -> String {
        let ruleChecks = task.styleRules.map { ruleID in
            generateRuleCheck(for: ruleID)
        }.joined(separator: "\n\n")

        return """
        import XCTest
        import SwiftSyntax
        import SwiftParser

        final class StyleAnalysisTests: XCTestCase {
            private var sourceCode: String!
            private var syntax: SourceFileSyntax!

            override func setUp() {
                super.setUp()
                // Read the generated code file
                let sourcePath = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("Sources/GeneratedCode/GeneratedCode.swift")

                sourceCode = try? String(contentsOf: sourcePath)
                if let code = sourceCode {
                    syntax = Parser.parse(source: code)
                }
            }

        \(ruleChecks)
        }

        // MARK: - Syntax Visitors

        /// Visitor that checks for specific patterns in the AST
        private final class PatternVisitor: SyntaxVisitor {
            var foundObservable = false
            var foundMainActor = false
            var foundNavigationStack = false
            var foundTabAPI = false
            var foundAsyncAwait = false
            var foundSendable = false
            var foundForegroundStyle = false
            var foundClipShapeRect = false
            var foundScaledMetric = false
            var foundScrollIndicators = false
            var foundContentUnavailable = false
            var foundSwiftDataModel = false
            var foundQuery = false
            var foundAccessibilityLabel = false
            var foundAccessibilityValue = false
            var foundDispatchQueue = false
            var foundObservableObject = false
            var foundPublished = false
            var foundForegroundColor = false
            var foundCornerRadius = false
            var foundTabItem = false
            var foundNavigationView = false
            var foundForceUnwrap = false
            var foundForceTry = false
            var foundUIScreenMain = false
            var foundDocComments = false
            var foundMarkComments = false
            var foundPrivateAccess = false
            var foundGuardStatements = false

            override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
                let name = node.attributeName.trimmedDescription
                switch name {
                case "Observable":
                    foundObservable = true
                case "MainActor":
                    foundMainActor = true
                case "Model":
                    foundSwiftDataModel = true
                case "Query":
                    foundQuery = true
                case "ScaledMetric":
                    foundScaledMetric = true
                case "Published":
                    foundPublished = true
                case "Bindable":
                    break
                default:
                    break
                }
                return .visitChildren
            }

            override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
                let calledName = node.calledExpression.trimmedDescription
                if calledName.contains("NavigationStack") {
                    foundNavigationStack = true
                }
                if calledName.contains("Tab(") || calledName == "Tab" {
                    foundTabAPI = true
                }
                if calledName.contains("foregroundStyle") {
                    foundForegroundStyle = true
                }
                if calledName.contains("clipShape") {
                    foundClipShapeRect = true
                }
                if calledName.contains("scrollIndicators") {
                    foundScrollIndicators = true
                }
                if calledName.contains("ContentUnavailableView") {
                    foundContentUnavailable = true
                }
                if calledName.contains("accessibilityLabel") {
                    foundAccessibilityLabel = true
                }
                if calledName.contains("accessibilityValue") {
                    foundAccessibilityValue = true
                }
                if calledName.contains("DispatchQueue") {
                    foundDispatchQueue = true
                }
                if calledName.contains("foregroundColor") {
                    foundForegroundColor = true
                }
                if calledName.contains("cornerRadius") {
                    foundCornerRadius = true
                }
                if calledName.contains("tabItem") {
                    foundTabItem = true
                }
                if calledName.contains("NavigationView") {
                    foundNavigationView = true
                }
                if calledName.contains("UIScreen.main") {
                    foundUIScreenMain = true
                }
                return .visitChildren
            }

            override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
                let typeName = node.type.trimmedDescription
                if typeName == "ObservableObject" {
                    foundObservableObject = true
                }
                if typeName == "Sendable" {
                    foundSendable = true
                }
                return .visitChildren
            }

            override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
                if node.signature.effectSpecifiers?.asyncSpecifier != nil {
                    foundAsyncAwait = true
                }
                return .visitChildren
            }

            override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
                foundAsyncAwait = true
                return .visitChildren
            }

            override func visit(_ node: ForceUnwrapExprSyntax) -> SyntaxVisitorContinueKind {
                foundForceUnwrap = true
                return .visitChildren
            }

            override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
                if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
                    foundForceTry = true
                }
                return .visitChildren
            }

            override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
                if node.name.tokenKind == .keyword(.private) {
                    foundPrivateAccess = true
                }
                return .visitChildren
            }

            override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
                foundGuardStatements = true
                return .visitChildren
            }

            override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
                // Check trivia for comments
                for piece in node.leadingTrivia {
                    switch piece {
                    case let .docLineComment(text):
                        foundDocComments = true
                        if text.contains("// MARK:") {
                            foundMarkComments = true
                        }
                    case let .lineComment(text):
                        if text.contains("// MARK:") {
                            foundMarkComments = true
                        }
                    default:
                        break
                    }
                }
                return .visitChildren
            }
        }
        """
    }

    private static func generateRuleCheck(for ruleID: StyleRuleIdentifier) -> String {
        let rule = StyleRule.rule(for: ruleID)
        let testName = ruleID
            .replacing("-", with: "")
            .split(separator: "-")
            .enumerated()
            .map { $0.offset == 0 ? $0.element.lowercased() : $0.element.capitalized }
            .joined()

        // Generate the appropriate assertion based on the rule
        switch ruleID {
        case StyleRules.useObservable:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertTrue(visitor.foundObservable, "@Observable macro not found")
                }
            """
        case StyleRules.useMainActor:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertTrue(visitor.foundMainActor, "@MainActor not found")
                }
            """
        case StyleRules.useNavigationStack:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertTrue(visitor.foundNavigationStack, "NavigationStack not found")
                }
            """
        case StyleRules.useTabAPI:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertTrue(visitor.foundTabAPI, "Tab API not found")
                }
            """
        case StyleRules.useAsyncAwait:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertTrue(visitor.foundAsyncAwait, "async/await not found")
                }
            """
        case StyleRules.noDispatchQueue:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertFalse(visitor.foundDispatchQueue, "DispatchQueue should not be used")
                }
            """
        case StyleRules.noObservableObject:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertFalse(visitor.foundObservableObject, "ObservableObject should not be used")
                }
            """
        case StyleRules.noForceUnwrap:
            return """
                func test\(testName.capitalized)() {
                    guard let syntax else { XCTFail("Failed to parse source"); return }
                    let visitor = PatternVisitor(viewMode: .sourceAccurate)
                    visitor.walk(syntax)
                    XCTAssertFalse(visitor.foundForceUnwrap, "Force unwrap (!) should not be used")
                }
            """
        default:
            // Generate a generic check for other rules
            return """
                func test\(testName.capitalized)() {
                    // Rule: \(ruleID)
                    // TODO: Implement specific check for this rule
                    XCTAssertTrue(true, "Rule check placeholder")
                }
            """
        }
    }
}

#endif

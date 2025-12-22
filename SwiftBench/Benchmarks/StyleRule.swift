//
//  StyleRule.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// A style rule for AST-based code analysis.
///
/// Style rules define checks that run during test execution using SwiftSyntax.
/// They verify that generated code follows modern Swift/SwiftUI patterns
/// by analyzing the actual code structure, not string matching.
struct StyleRule: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier matching the StyleRuleIdentifier.
    let id: StyleRuleIdentifier

    /// Human-readable name for the rule.
    let name: String

    /// Detailed description of what this rule checks.
    let description: String

    /// Category of this style rule.
    let category: StyleCategory

    /// Weight in the overall style score (0.0 to 1.0).
    let weight: Double

    /// Whether this is an anti-pattern rule (penalizes if found).
    let isAntiPattern: Bool

    /// Creates a new style rule.
    init(
        id: StyleRuleIdentifier,
        name: String,
        description: String,
        category: StyleCategory,
        weight: Double = 1.0,
        isAntiPattern: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.weight = weight
        self.isAntiPattern = isAntiPattern
    }
}

// MARK: - StyleCategory

/// Categories for grouping related style rules.
enum StyleCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case modernAPIs
    case concurrency
    case accessibility
    case documentation
    case antiPatterns
    case swiftData
    case codeQuality

    var id: String { rawValue }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .modernAPIs:
            "Modern APIs"
        case .concurrency:
            "Concurrency"
        case .accessibility:
            "Accessibility"
        case .documentation:
            "Documentation"
        case .antiPatterns:
            "Anti-Patterns"
        case .swiftData:
            "SwiftData"
        case .codeQuality:
            "Code Quality"
        }
    }

    /// SF Symbol for this category.
    var systemImage: String {
        switch self {
        case .modernAPIs:
            "sparkles"
        case .concurrency:
            "arrow.triangle.branch"
        case .accessibility:
            "accessibility"
        case .documentation:
            "doc.text"
        case .antiPatterns:
            "xmark.circle"
        case .swiftData:
            "cylinder"
        case .codeQuality:
            "checkmark.seal"
        }
    }
}

// MARK: - Predefined Style Rules

extension StyleRule {
    /// All predefined style rules.
    static let allRules: [StyleRule] = [
        // Modern APIs
        StyleRule(
            id: StyleRules.useObservable,
            name: "@Observable",
            description: "Uses @Observable macro instead of ObservableObject",
            category: .modernAPIs,
            weight: 1.0
        ),
        StyleRule(
            id: StyleRules.useMainActor,
            name: "@MainActor",
            description: "Uses @MainActor for main-thread isolation",
            category: .concurrency,
            weight: 1.0
        ),
        StyleRule(
            id: StyleRules.useNavigationStack,
            name: "NavigationStack",
            description: "Uses NavigationStack instead of NavigationView",
            category: .modernAPIs,
            weight: 1.0
        ),
        StyleRule(
            id: StyleRules.useTabAPI,
            name: "Tab API",
            description: "Uses Tab() API instead of tabItem()",
            category: .modernAPIs,
            weight: 1.0
        ),
        StyleRule(
            id: StyleRules.useAsyncAwait,
            name: "async/await",
            description: "Uses Swift concurrency instead of callbacks",
            category: .concurrency,
            weight: 1.0
        ),
        StyleRule(
            id: StyleRules.useSendable,
            name: "Sendable",
            description: "Marks types as Sendable for thread safety",
            category: .concurrency,
            weight: 0.5
        ),
        StyleRule(
            id: StyleRules.useForegroundStyle,
            name: "foregroundStyle()",
            description: "Uses foregroundStyle() instead of foregroundColor()",
            category: .modernAPIs,
            weight: 0.8
        ),
        StyleRule(
            id: StyleRules.useClipShapeRect,
            name: "clipShape(.rect)",
            description: "Uses clipShape(.rect(cornerRadius:)) instead of cornerRadius()",
            category: .modernAPIs,
            weight: 0.8
        ),
        StyleRule(
            id: StyleRules.useScaledMetric,
            name: "@ScaledMetric",
            description: "Uses @ScaledMetric for Dynamic Type support",
            category: .accessibility,
            weight: 0.6
        ),
        StyleRule(
            id: StyleRules.useScrollIndicators,
            name: "scrollIndicators()",
            description: "Uses scrollIndicators() modifier instead of showsIndicators parameter",
            category: .modernAPIs,
            weight: 0.5
        ),
        StyleRule(
            id: StyleRules.useContentUnavailable,
            name: "ContentUnavailableView",
            description: "Uses ContentUnavailableView for empty states",
            category: .modernAPIs,
            weight: 0.5
        ),

        // SwiftData
        StyleRule(
            id: StyleRules.useSwiftDataModel,
            name: "@Model",
            description: "Uses SwiftData @Model for persistence",
            category: .swiftData,
            weight: 1.0
        ),
        StyleRule(
            id: StyleRules.useQuery,
            name: "@Query",
            description: "Uses @Query for SwiftData queries",
            category: .swiftData,
            weight: 0.8
        ),

        // Accessibility
        StyleRule(
            id: StyleRules.useAccessibilityLabel,
            name: "accessibilityLabel",
            description: "Provides accessibility labels for UI elements",
            category: .accessibility,
            weight: 0.7
        ),
        StyleRule(
            id: StyleRules.useAccessibilityValue,
            name: "accessibilityValue",
            description: "Provides accessibility values for dynamic content",
            category: .accessibility,
            weight: 0.5
        ),

        // Anti-patterns (penalize if found)
        StyleRule(
            id: StyleRules.noDispatchQueue,
            name: "No DispatchQueue",
            description: "Avoids DispatchQueue in favor of async/await",
            category: .antiPatterns,
            weight: 1.0,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noObservableObject,
            name: "No ObservableObject",
            description: "Avoids deprecated ObservableObject protocol",
            category: .antiPatterns,
            weight: 1.0,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noPublished,
            name: "No @Published",
            description: "Avoids @Published in favor of @Observable",
            category: .antiPatterns,
            weight: 0.8,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noForegroundColor,
            name: "No foregroundColor()",
            description: "Avoids deprecated foregroundColor() modifier",
            category: .antiPatterns,
            weight: 0.6,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noCornerRadius,
            name: "No cornerRadius()",
            description: "Avoids deprecated cornerRadius() modifier",
            category: .antiPatterns,
            weight: 0.6,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noTabItem,
            name: "No tabItem()",
            description: "Avoids deprecated tabItem() modifier",
            category: .antiPatterns,
            weight: 0.8,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noNavigationView,
            name: "No NavigationView",
            description: "Avoids deprecated NavigationView",
            category: .antiPatterns,
            weight: 1.0,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noForceUnwrap,
            name: "No Force Unwrap",
            description: "Avoids force unwrap (!) operators",
            category: .antiPatterns,
            weight: 0.8,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noForceTry,
            name: "No Force Try",
            description: "Avoids force try (try!) operators",
            category: .antiPatterns,
            weight: 0.8,
            isAntiPattern: true
        ),
        StyleRule(
            id: StyleRules.noUIScreenMain,
            name: "No UIScreen.main",
            description: "Avoids deprecated UIScreen.main.bounds",
            category: .antiPatterns,
            weight: 0.6,
            isAntiPattern: true
        ),

        // Code Quality
        StyleRule(
            id: StyleRules.hasDocumentation,
            name: "Documentation",
            description: "Includes /// documentation comments",
            category: .documentation,
            weight: 0.5
        ),
        StyleRule(
            id: StyleRules.hasMarkComments,
            name: "MARK Comments",
            description: "Uses // MARK: for code organization",
            category: .documentation,
            weight: 0.3
        ),
        StyleRule(
            id: StyleRules.usesPrivateAccess,
            name: "Private Access",
            description: "Uses private access control appropriately",
            category: .codeQuality,
            weight: 0.4
        ),
        StyleRule(
            id: StyleRules.usesGuardStatements,
            name: "Guard Statements",
            description: "Uses guard for early returns",
            category: .codeQuality,
            weight: 0.3
        ),
    ]

    /// Gets a style rule by its identifier.
    static func rule(for id: StyleRuleIdentifier) -> StyleRule? {
        allRules.first { $0.id == id }
    }

    /// Gets all rules for a specific category.
    static func rules(for category: StyleCategory) -> [StyleRule] {
        allRules.filter { $0.category == category }
    }

    /// Gets all anti-pattern rules.
    static var antiPatternRules: [StyleRule] {
        allRules.filter(\.isAntiPattern)
    }

    /// Gets all positive (non-anti-pattern) rules.
    static var positiveRules: [StyleRule] {
        allRules.filter { !$0.isAntiPattern }
    }
}

//
//  BenchmarkCategory.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Categories of benchmark tasks for organizing and grouping related tests.
enum BenchmarkCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case algorithms
    case dataModeling
    case concurrency
    case swiftUIComposition
    case swiftDataQueries
    case refactorsBugfixes

    var id: String { rawValue }

    /// Human-readable display name for the category.
    var displayName: String {
        switch self {
        case .algorithms:
            "Algorithms"
        case .dataModeling:
            "Data Modeling"
        case .concurrency:
            "Concurrency"
        case .swiftUIComposition:
            "SwiftUI Composition"
        case .swiftDataQueries:
            "SwiftData Queries"
        case .refactorsBugfixes:
            "Refactors & Bug Fixes"
        }
    }

    /// SF Symbol name representing this category.
    var systemImage: String {
        switch self {
        case .algorithms:
            "function"
        case .dataModeling:
            "cylinder.split.1x2"
        case .concurrency:
            "arrow.triangle.branch"
        case .swiftUIComposition:
            "square.grid.2x2"
        case .swiftDataQueries:
            "magnifyingglass"
        case .refactorsBugfixes:
            "wrench.and.screwdriver"
        }
    }

    /// Brief description of what this category tests.
    var description: String {
        switch self {
        case .algorithms:
            "Classic algorithms and data structure implementations"
        case .dataModeling:
            "SwiftData models, relationships, and schema design"
        case .concurrency:
            "async/await, actors, Sendable, and structured concurrency"
        case .swiftUIComposition:
            "View composition, navigation, state management"
        case .swiftDataQueries:
            "Predicates, sorting, filtering, and query optimization"
        case .refactorsBugfixes:
            "Modernizing deprecated patterns and fixing bugs"
        }
    }
}

/// Difficulty level of a benchmark task.
enum TaskDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    /// Human-readable display name for the difficulty.
    var displayName: String {
        switch self {
        case .easy:
            "Easy"
        case .medium:
            "Medium"
        case .hard:
            "Hard"
        }
    }

    /// Color associated with this difficulty level.
    var colorName: String {
        switch self {
        case .easy:
            "green"
        case .medium:
            "orange"
        case .hard:
            "red"
        }
    }
}

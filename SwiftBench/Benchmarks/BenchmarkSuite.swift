//
//  BenchmarkSuite.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// A collection of benchmark tasks organized as a versioned suite.
///
/// Suites group related tasks and provide metadata for aggregate scoring.
struct BenchmarkSuite: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for this suite.
    let id: String

    /// Version string for this suite (e.g., "2.0").
    let version: String

    /// Human-readable title for the suite.
    let title: String

    /// Detailed description of what this suite tests.
    let description: String

    /// All tasks included in this suite.
    let tasks: [BenchmarkTask]

    /// Creates a new benchmark suite.
    init(
        id: String,
        version: String,
        title: String,
        description: String,
        tasks: [BenchmarkTask]
    ) {
        self.id = id
        self.version = version
        self.title = title
        self.description = description
        self.tasks = tasks
    }

    /// Tasks grouped by category.
    var tasksByCategory: [BenchmarkCategory: [BenchmarkTask]] {
        Dictionary(grouping: tasks, by: \.category)
    }

    /// Tasks grouped by difficulty.
    var tasksByDifficulty: [TaskDifficulty: [BenchmarkTask]] {
        Dictionary(grouping: tasks, by: \.difficulty)
    }

    /// Number of tasks in each category.
    var categoryCounts: [BenchmarkCategory: Int] {
        tasksByCategory.mapValues(\.count)
    }

    /// Number of tasks in each difficulty level.
    var difficultyCounts: [TaskDifficulty: Int] {
        tasksByDifficulty.mapValues(\.count)
    }

    /// Total number of tasks in the suite.
    var taskCount: Int {
        tasks.count
    }

    /// Number of tasks that have executable tests.
    var testableTaskCount: Int {
        tasks.filter(\.hasTests).count
    }

    /// Gets all tasks for a specific category.
    func tasks(for category: BenchmarkCategory) -> [BenchmarkTask] {
        tasksByCategory[category] ?? []
    }

    /// Gets all tasks for a specific difficulty.
    func tasks(for difficulty: TaskDifficulty) -> [BenchmarkTask] {
        tasksByDifficulty[difficulty] ?? []
    }

    /// Finds a task by its ID.
    func task(withID id: String) -> BenchmarkTask? {
        tasks.first { $0.id == id }
    }
}

// MARK: - Suite Run Progress

/// Tracks progress during a suite run.
struct SuiteRunProgress: Sendable, Equatable {
    /// Total number of tasks in the suite.
    let totalTasks: Int

    /// Number of tasks completed so far.
    let completedTasks: Int

    /// The task currently being executed (nil if between tasks).
    let currentTask: BenchmarkTask?

    /// Current run index for pass@k (0-based).
    let currentRunIndex: Int

    /// Total number of runs per task (k value).
    let runsPerTask: Int

    /// Overall progress as a fraction (0.0 to 1.0).
    var progress: Double {
        let totalRuns = totalTasks * runsPerTask
        let completedRuns = completedTasks * runsPerTask + currentRunIndex
        return totalRuns > 0 ? Double(completedRuns) / Double(totalRuns) : 0
    }

    /// Progress as a percentage string.
    var progressPercentage: String {
        "\(Int(progress * 100))%"
    }

    /// Whether the suite run is complete.
    var isComplete: Bool {
        completedTasks >= totalTasks
    }

    /// Equatable conformance.
    static func == (lhs: SuiteRunProgress, rhs: SuiteRunProgress) -> Bool {
        lhs.totalTasks == rhs.totalTasks &&
        lhs.completedTasks == rhs.completedTasks &&
        lhs.currentTask?.id == rhs.currentTask?.id &&
        lhs.currentRunIndex == rhs.currentRunIndex &&
        lhs.runsPerTask == rhs.runsPerTask
    }
}

//
//  BenchmarkSpec.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

struct BenchmarkSpec: Identifiable, Hashable {
    let id: String
    let title: String
    let prompt: String
    let benchmarkCode: String

    static let swiftBench = BenchmarkSpec(
        id: "swiftbench-v1",
        title: "SwiftBench Benchmark v1",
        prompt: """
You are writing a cross-platform SwiftUI app for iOS 26, iPadOS 26, and macOS 26.

Requirements:
- Use @MainActor @Observable app state for view logic.
- Persist leaderboard entries with SwiftData @Model (all properties must have default values).
- Use NavigationStack and TabView with the Tab API (Tab(\"Title\", systemImage: \"...\") { }).
- Include AppKit and UIKit via NSViewRepresentable/UIViewRepresentable for a monospaced code viewer.
- Use async/await, avoid GCD, avoid force unwraps.
- Use foregroundStyle() and clipShape(.rect(cornerRadius:)).
- Use ContentUnavailableView for empty states.
- Use @ScaledMetric for Dynamic Type support.
- Use scrollIndicators(.hidden) instead of showsIndicators parameter.
- Provide a scoring function that compares generated code to a benchmark string.
- Add proper documentation comments (/// for public APIs, // MARK: for sections).
- Follow Apple Human Interface Guidelines for spacing and layout.
- Use accessibilityLabel and accessibilityValue for key UI elements.
- Return only Swift code (no Markdown, no explanations).
""",
        benchmarkCode: #"""
// MARK: - LeaderboardEntry.swift
// SwiftData model for persisting benchmark results

import Foundation
import SwiftData

/// A persisted record of a single benchmark run result.
@Model
final class LeaderboardEntry {
    /// Unique identifier for this entry.
    var id = UUID()

    /// Timestamp when the benchmark was executed.
    var createdAt = Date.now

    /// The model identifier used for this benchmark run.
    var modelIdentifier = ""

    /// The score achieved (0-100 scale).
    var score = 0.0

    /// Total tokens consumed during the run.
    var tokenTotal = 0

    /// Creates a new leaderboard entry with the specified values.
    /// - Parameters:
    ///   - modelIdentifier: The LLM model identifier.
    ///   - score: The benchmark score achieved.
    ///   - tokenTotal: Total tokens used.
    init(modelIdentifier: String, score: Double, tokenTotal: Int) {
        self.modelIdentifier = modelIdentifier
        self.score = score
        self.tokenTotal = tokenTotal
    }
}

// MARK: - BenchmarkState.swift
// Observable state for managing benchmark execution

import Observation
import SwiftUI

/// Main application state managing benchmark execution and results.
@MainActor
@Observable
final class BenchmarkState {
    // MARK: Properties

    /// The prompt to send to the LLM.
    var prompt = "Write the SwiftUI app described in the requirements."

    /// The generated output from the LLM.
    var output = ""

    /// The calculated benchmark score.
    var score = 0.0

    /// Whether a benchmark is currently running.
    var isRunning = false

    // MARK: Methods

    /// Calculates and updates the score based on generated output.
    /// - Parameter benchmark: The reference benchmark code to compare against.
    func updateScore(benchmark: String) {
        let report = ScoreCalculator().score(generated: output, benchmark: benchmark)
        score = report
    }
}

// MARK: - RootView.swift
// Main tab-based navigation structure

import SwiftUI

/// The root view containing the main tab navigation.
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Run", systemImage: "bolt.fill") {
                NavigationStack { RunView() }
            }
            Tab("Leaderboard", systemImage: "list.number") {
                NavigationStack { LeaderboardView() }
            }
        }
    }
}

// MARK: - RunView.swift
// Benchmark execution interface

import SwiftUI

/// View for running benchmarks and displaying results.
struct RunView: View {
    @Environment(BenchmarkState.self) private var state

    @ScaledMetric private var spacing = 16
    @ScaledMetric private var cornerRadius = 12

    var body: some View {
        @Bindable var state = state

        ScrollView {
            VStack(spacing: spacing) {
                promptEditor
                outputViewer
                scoreDisplay
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Run")
    }

    // MARK: Private Views

    private var promptEditor: some View {
        TextEditor(text: $state.prompt)
            .font(.body.monospaced())
            .frame(minHeight: 120)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .accessibilityLabel("Prompt editor")
    }

    private var outputViewer: some View {
        CodeTextView(text: state.output)
            .frame(minHeight: 200)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .accessibilityLabel("Generated output")
    }

    private var scoreDisplay: some View {
        Text("Score: \(state.score, format: .number.precision(.fractionLength(1)))")
            .foregroundStyle(.secondary)
            .accessibilityLabel("Score")
            .accessibilityValue(Text(state.score, format: .number.precision(.fractionLength(1))))
    }
}

// MARK: - LeaderboardView.swift
// Ranked list of benchmark results

import SwiftData
import SwiftUI

/// Displays a ranked list of all benchmark runs sorted by score.
struct LeaderboardView: View {
    @Query(sort: [SortDescriptor(\LeaderboardEntry.score, order: .reverse)])
    private var entries: [LeaderboardEntry]

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Run a benchmark to see results.")
                )
            } else {
                List(entries.enumerated(), id: \.element.id) { index, entry in
                    LeaderboardRowView(rank: index + 1, entry: entry)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Leaderboard")
    }
}

// MARK: - LeaderboardRowView.swift
// Individual leaderboard entry display

import SwiftUI

/// Displays a single leaderboard entry with rank, model, and score.
struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry

    @ScaledMetric private var spacing = 8

    var body: some View {
        HStack(spacing: spacing) {
            rankBadge
            modelInfo
            Spacer()
            scoreBadge
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.modelIdentifier), rank \(rank), score \(Int(entry.score))")
    }

    // MARK: Private Views

    private var rankBadge: some View {
        Text("#\(rank)")
            .font(.headline.monospacedDigit())
            .foregroundStyle(rank <= 3 ? .primary : .secondary)
    }

    private var modelInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.modelIdentifier)
                .font(.headline)
                .lineLimit(1)
            Text("Tokens: \(entry.tokenTotal)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var scoreBadge: some View {
        Text(entry.score, format: .number.precision(.fractionLength(1)))
            .font(.title3.bold().monospacedDigit())
            .foregroundStyle(scoreColor)
    }

    private var scoreColor: Color {
        switch entry.score {
        case 80...: .green
        case 60..<80: .orange
        default: .red
        }
    }
}

// MARK: - CodeTextView.swift
// Platform-specific code display using AppKit/UIKit

import SwiftUI

#if os(macOS)
import AppKit

/// A macOS-native text view for displaying code with monospaced font.
struct CodeTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.string = text
    }
}
#else
import UIKit

/// An iOS-native text view for displaying code with monospaced font.
struct CodeTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = true

        let baseFont = UIFont.monospacedSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        view.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
        view.adjustsFontForContentSizeCategory = true

        let inset = UIFontMetrics(forTextStyle: .body).scaledValue(for: 8)
        view.textContainerInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
#endif

// MARK: - ScoreCalculator.swift
// Benchmark scoring algorithm

import Foundation

/// Calculates similarity scores between generated and benchmark code.
struct ScoreCalculator: Sendable {
    /// Calculates a similarity score between generated and benchmark code.
    /// - Parameters:
    ///   - generated: The LLM-generated code.
    ///   - benchmark: The reference benchmark code.
    /// - Returns: A score from 0-100 representing similarity.
    func score(generated: String, benchmark: String) -> Double {
        let generatedTokens = tokenize(generated)
        let benchmarkTokens = tokenize(benchmark)

        guard !benchmarkTokens.isEmpty else { return 0 }

        let intersection = generatedTokens.intersection(benchmarkTokens)
        let union = generatedTokens.union(benchmarkTokens)

        let jaccardScore = Double(intersection.count) / Double(max(union.count, 1))
        return jaccardScore * 100
    }

    // MARK: Private Methods

    private func tokenize(_ text: String) -> Set<String> {
        Set(
            text.lowercased()
                .split { !$0.isLetter && !$0.isNumber && $0 != "_" }
                .filter { $0.count > 2 }
                .map(String.init)
        )
    }
}
"""#
    )

    static let all: [BenchmarkSpec] = [
        .swiftBench,
    ]
}

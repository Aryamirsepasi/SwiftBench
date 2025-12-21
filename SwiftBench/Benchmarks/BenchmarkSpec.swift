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
- Return only Swift code (no Markdown, no explanations).
""",
        benchmarkCode: #"""
// File: LeaderboardEntry.swift
import Foundation
import SwiftData

@Model
final class LeaderboardEntry {
    var id = UUID()
    var createdAt = Date.now
    var modelIdentifier = ""
    var score = 0.0
    var tokenTotal = 0

    init(modelIdentifier: String, score: Double, tokenTotal: Int) {
        self.modelIdentifier = modelIdentifier
        self.score = score
        self.tokenTotal = tokenTotal
    }
}

// File: BenchmarkState.swift
import Observation
import SwiftUI

@MainActor
@Observable
final class BenchmarkState {
    var prompt = "Write the SwiftUI app described in the requirements."
    var output = ""
    var score = 0.0
    var isRunning = false

    func updateScore(benchmark: String) {
        let report = ScoreCalculator().score(generated: output, benchmark: benchmark)
        score = report
    }
}

// File: RootView.swift
import SwiftUI

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

// File: RunView.swift
import SwiftUI

struct RunView: View {
    @Environment(BenchmarkState.self) private var state
    @ScaledMetric private var spacing = 16
    @ScaledMetric private var cornerRadius = 12

    var body: some View {
        @Bindable var state = state
        ScrollView {
            VStack(spacing: spacing) {
                TextEditor(text: $state.prompt)
                    .font(.body.monospaced())
                    .frame(minHeight: 120)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                CodeTextView(text: state.output)
                    .frame(minHeight: 200)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                Text("Score: \(state.score, format: .number.precision(.fractionLength(1)))")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Run")
    }
}

// File: LeaderboardView.swift
import SwiftData
import SwiftUI

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
                List(entries) { entry in
                    LeaderboardRowView(entry: entry)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Leaderboard")
    }
}

// File: LeaderboardRowView.swift
import SwiftUI

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    @ScaledMetric private var spacing = 6

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(entry.modelIdentifier)
                .font(.headline)
            Text("Score \(entry.score, format: .number.precision(.fractionLength(1)))")
                .foregroundStyle(.secondary)
            Text("Tokens: \(entry.tokenTotal)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// File: CodeTextView.swift
import SwiftUI

#if os(macOS)
import AppKit

struct CodeTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.isEditable = false
        view.drawsBackground = false
        view.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return view
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.string = text
    }
}
#else
import UIKit

struct CodeTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear
        let baseFont = UIFont.monospacedSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        view.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
        view.adjustsFontForContentSizeCategory = true
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
#endif

// File: ScoreCalculator.swift
import Foundation

struct ScoreCalculator: Sendable {
    func score(generated: String, benchmark: String) -> Double {
        let generatedTokens = tokenize(generated)
        let benchmarkTokens = tokenize(benchmark)
        let overlap = Double(generatedTokens.intersection(benchmarkTokens).count)
        let union = Double(max(generatedTokens.union(benchmarkTokens).count, 1))
        return (overlap / union) * 100
    }

    private func tokenize(_ text: String) -> Set<String> {
        Set(
            text.lowercased()
                .split { !$0.isLetter && !$0.isNumber }
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

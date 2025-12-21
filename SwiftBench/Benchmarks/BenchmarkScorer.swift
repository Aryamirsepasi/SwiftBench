//
//  BenchmarkScorer.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

struct BenchmarkScorer {
    private let keywords = [
        "@Observable",
        "@MainActor",
        "SwiftData",
        "@Model",
        "NavigationStack",
        "TabView",
        "Tab(\"",
        "NSViewRepresentable",
        "UIViewRepresentable",
        "async",
        "await",
        "foregroundStyle",
        "clipShape(.rect",
        "ContentUnavailableView",
        "@ScaledMetric",
        "scrollIndicators(.hidden)",
        "@Bindable",
        "Sendable",
    ]

    func score(generated: String, benchmark: String) -> BenchmarkScoreReport {
        let normalizedGenerated = normalize(generated)
        let normalizedBenchmark = normalize(benchmark)

        let generatedTokens = tokenSet(from: normalizedGenerated)
        let benchmarkTokens = tokenSet(from: normalizedBenchmark)

        let tokenScore = jaccardScore(generatedTokens, benchmarkTokens)
        let lineScore = jaccardScore(lineSet(from: normalizedGenerated), lineSet(from: normalizedBenchmark))
        let keywordScore = keywordMatchScore(in: normalizedGenerated)
        let lengthScore = lengthSimilarityScore(generatedTokens.count, benchmarkTokens.count)

        let weightedScore = (
            tokenScore * 0.45
            + lineScore * 0.25
            + keywordScore * 0.20
            + lengthScore * 0.10
        )

        let components = [
            BenchmarkScoreComponent(id: "token", label: "Token overlap", value: tokenScore, weight: 0.45),
            BenchmarkScoreComponent(id: "line", label: "Line overlap", value: lineScore, weight: 0.25),
            BenchmarkScoreComponent(id: "keyword", label: "API coverage", value: keywordScore, weight: 0.20),
            BenchmarkScoreComponent(id: "length", label: "Length match", value: lengthScore, weight: 0.10),
        ]

        let clamped = min(max(weightedScore, 0), 1)
        return BenchmarkScoreReport(score: clamped * 100, components: components)
    }

    private func normalize(_ text: String) -> String {
        text
            .replacing("\r\n", with: "\n")
            .replacing("\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenSet(from text: String) -> Set<String> {
        let tokens = text
            .lowercased()
            .split { character in
                !(character.isLetter || character.isNumber || character == "_")
            }
            .filter { $0.count > 2 }
            .map(String.init)
        return Set(tokens)
    }

    private func lineSet(from text: String) -> Set<String> {
        let lines = text
            .split(whereSeparator: \Character.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 2 }
        return Set(lines)
    }

    private func jaccardScore(_ left: Set<String>, _ right: Set<String>) -> Double {
        guard !(left.isEmpty && right.isEmpty) else { return 1 }
        let intersection = left.intersection(right).count
        let union = left.union(right).count
        return Double(intersection) / Double(max(union, 1))
    }

    private func keywordMatchScore(in text: String) -> Double {
        let matchCount = keywords.filter { text.localizedCaseInsensitiveContains($0) }.count
        return Double(matchCount) / Double(max(keywords.count, 1))
    }

    private func lengthSimilarityScore(_ generatedCount: Int, _ benchmarkCount: Int) -> Double {
        let benchmarkCount = max(benchmarkCount, 1)
        let delta = abs(Double(generatedCount - benchmarkCount))
        let ratio = delta / Double(benchmarkCount)
        return 1 - min(max(ratio, 0), 1)
    }
}

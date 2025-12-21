//
//  BenchmarkScorer.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

/// Scores generated code against a benchmark using multiple quality dimensions.
struct BenchmarkScorer {
    // MARK: - Modern API Keywords

    private let modernAPIKeywords = [
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
        "accessibilityLabel",
        "accessibilityValue",
    ]

    // MARK: - Code Quality Indicators

    private let codeQualityIndicators = [
        "// MARK:",
        "/// ",
        "private var",
        "private func",
        "private let",
        ".accessibilityElement",
        ".lineLimit",
        "guard ",
        "let ",
    ]

    // MARK: - Anti-patterns to Penalize

    private let antiPatterns = [
        "DispatchQueue",
        "ObservableObject",
        "@Published",
        "foregroundColor(",
        "cornerRadius(",
        ".tabItem(",
        "NavigationView",
        "UIScreen.main",
        "showsIndicators:",
        "try!",
        "as!",
    ]

    // MARK: - Scoring

    func score(generated: String, benchmark: String) -> BenchmarkScoreReport {
        let normalizedGenerated = normalize(generated)
        let normalizedBenchmark = normalize(benchmark)

        let generatedTokens = tokenSet(from: normalizedGenerated)
        let benchmarkTokens = tokenSet(from: normalizedBenchmark)

        // Core similarity metrics
        let tokenScore = jaccardScore(generatedTokens, benchmarkTokens)
        let lineScore = jaccardScore(lineSet(from: normalizedGenerated), lineSet(from: normalizedBenchmark))
        let apiScore = keywordMatchScore(keywords: modernAPIKeywords, in: normalizedGenerated)
        let lengthScore = lengthSimilarityScore(generatedTokens.count, benchmarkTokens.count)

        // Code quality metrics
        let qualityScore = keywordMatchScore(keywords: codeQualityIndicators, in: normalizedGenerated)
        let antiPatternPenalty = antiPatternPenaltyScore(in: normalizedGenerated)

        // Weighted calculation (totals 1.0 before penalty)
        let baseScore = (
            tokenScore * 0.35
            + lineScore * 0.20
            + apiScore * 0.20
            + qualityScore * 0.15
            + lengthScore * 0.10
        )

        // Apply anti-pattern penalty (reduces score by up to 20%)
        let penalizedScore = baseScore * (1.0 - antiPatternPenalty * 0.20)

        let components = [
            BenchmarkScoreComponent(id: "token", label: "Token overlap", value: tokenScore, weight: 0.35),
            BenchmarkScoreComponent(id: "line", label: "Line overlap", value: lineScore, weight: 0.20),
            BenchmarkScoreComponent(id: "api", label: "Modern APIs", value: apiScore, weight: 0.20),
            BenchmarkScoreComponent(id: "quality", label: "Code quality", value: qualityScore, weight: 0.15),
            BenchmarkScoreComponent(id: "length", label: "Length match", value: lengthScore, weight: 0.10),
        ]

        let clamped = min(max(penalizedScore, 0), 1)
        return BenchmarkScoreReport(score: clamped * 100, components: components)
    }

    // MARK: - Private Methods

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

    private func keywordMatchScore(keywords: [String], in text: String) -> Double {
        let matchCount = keywords.filter { text.localizedCaseInsensitiveContains($0) }.count
        return Double(matchCount) / Double(max(keywords.count, 1))
    }

    private func antiPatternPenaltyScore(in text: String) -> Double {
        let matchCount = antiPatterns.filter { text.localizedCaseInsensitiveContains($0) }.count
        return Double(matchCount) / Double(max(antiPatterns.count, 1))
    }

    private func lengthSimilarityScore(_ generatedCount: Int, _ benchmarkCount: Int) -> Double {
        let benchmarkCount = max(benchmarkCount, 1)
        let delta = abs(Double(generatedCount - benchmarkCount))
        let ratio = delta / Double(benchmarkCount)
        return 1 - min(max(ratio, 0), 1)
    }
}

//
//  SuiteResultsView.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import SwiftData
import SwiftUI

/// View displaying aggregate results from suite runs.
struct SuiteResultsView: View {
    @Query(sort: [SortDescriptor(\SuiteRunResult.createdAt, order: .reverse)])
    private var suiteResults: [SuiteRunResult]

    var body: some View {
        NavigationStack {
            Group {
                if suiteResults.isEmpty {
                    ContentUnavailableView(
                        "No Suite Results",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Run a benchmark suite to see aggregate results.")
                    )
                } else {
                    List(suiteResults) { result in
                        NavigationLink(value: result) {
                            SuiteResultRowView(result: result)
                        }
                    }
                    .navigationDestination(for: SuiteRunResult.self) { result in
                        SuiteResultDetailView(result: result)
                    }
                }
            }
            .navigationTitle("Suite Results")
        }
    }
}

// MARK: - Row View

/// Row displaying summary of a suite run result.
struct SuiteResultRowView: View {
    let result: SuiteRunResult

    @ScaledMetric private var sparklineHeight: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.modelIdentifier)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 8) {
                    ScoreBadge(score: result.meanScore)

                    Text(result.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack {
                Label(result.suiteTitle, systemImage: "list.bullet.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !result.categoryResults.isEmpty {
                    CategorySparklineView(categories: result.categoryResults, height: sparklineHeight)
                }
            }

            HStack(spacing: 16) {
                MetricBadge(label: "Pass@1", value: result.passAt1Percentage, format: "%")
                MetricBadge(label: "Mean", value: result.meanScore, format: "")
                MetricBadge(label: "Tasks", value: Double(result.passedTasks), format: "/\(result.totalTasks)")
            }
            .font(.caption2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

/// Detailed view of a suite run result.
struct SuiteResultDetailView: View {
    let result: SuiteRunResult

    var body: some View {
        List {
            overviewSection
            metricsSection
            categoryBreakdownSection
            tokensSection
        }
        .navigationTitle("Suite Result")
    }

    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("Model", value: result.modelIdentifier)

            if let provider = result.provider {
                LabeledContent("Provider", value: provider)
            }

            LabeledContent("Suite", value: result.suiteTitle)
            LabeledContent("Version", value: result.suiteVersion)
            LabeledContent("Date", value: result.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
    }

    private var metricsSection: some View {
        Section("Aggregate Metrics") {
            LabeledContent("Pass@1") {
                Text(result.passAt1Percentage, format: .number.precision(.fractionLength(1)))
                Text("%").foregroundStyle(.secondary)
            }

            if result.kValue > 1 {
                LabeledContent("Pass@\(result.kValue)") {
                    Text(result.passAtKPercentage, format: .number.precision(.fractionLength(1)))
                    Text("%").foregroundStyle(.secondary)
                }
            }

            LabeledContent("Mean Score") {
                Text(result.meanScore, format: .number.precision(.fractionLength(1)))
            }

            LabeledContent("Variance") {
                Text(result.scoreVariance, format: .number.precision(.fractionLength(2)))
            }

            LabeledContent("Style Score") {
                Text(result.meanStyleScore, format: .number.precision(.fractionLength(1)))
            }

            LabeledContent("Tasks Passed") {
                Text("\(result.passedTasks) / \(result.totalTasks)")
            }
        }
    }

    private var categoryBreakdownSection: some View {
        Section("Category Breakdown") {
            ForEach(result.categoryResults) { metrics in
                CategoryMetricsRowView(metrics: metrics)
            }
        }
    }

    private var tokensSection: some View {
        Section("Usage") {
            LabeledContent("Total Tokens", value: "\(result.totalTokensUsed)")

            if let cost = result.estimatedCost {
                LabeledContent("Estimated Cost") {
                    Text(cost, format: .currency(code: "USD"))
                }
            }

            LabeledContent("Execution Time") {
                Text(Duration.seconds(result.totalExecutionTime), format: .units(allowed: [.minutes, .seconds]))
            }

            LabeledContent("Temperature") {
                Text(result.temperature, format: .number.precision(.fractionLength(1)))
            }
        }
    }
}

// MARK: - Category Metrics Row

struct CategoryMetricsRowView: View {
    let metrics: CategoryMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(metrics.category.displayName, systemImage: metrics.category.systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(progressColor(for: metrics.passRate))

                Spacer()

                HStack(spacing: 4) {
                    Text("\(metrics.passedCount)/\(metrics.taskCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    CategoryBadge(passRate: metrics.passRate)
                }
            }

            ProgressView(value: metrics.passRate)
                .tint(progressColor(for: metrics.passRate))

            HStack {
                Text("Pass: \(metrics.passRatePercentage, format: .number.precision(.fractionLength(0)))%")
                Spacer()
                Text("Mean: \(metrics.meanScore, format: .number.precision(.fractionLength(1)))")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func progressColor(for rate: Double) -> Color {
        switch rate {
        case 0.8...: .green
        case 0.5..<0.8: .orange
        default: .red
        }
    }
}

/// Color-coded badge for category performance
struct CategoryBadge: View {
    let passRate: Double

    var body: some View {
        Text("\(Int(passRate * 100))%")
            .font(.caption2.weight(.medium))
            .foregroundStyle(progressColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(progressColor.opacity(0.15), in: .capsule)
    }

    private var progressColor: Color {
        switch passRate {
        case 0.8...: .green
        case 0.5..<0.8: .orange
        default: .red
        }
    }
}

// MARK: - Supporting Views

struct ScoreBadge: View {
    let score: Double

    var body: some View {
        Text(score, format: .number.precision(.fractionLength(1)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(scoreColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(scoreColor.opacity(0.15), in: .capsule)
    }

    private var scoreColor: Color {
        switch score {
        case 80...: .green
        case 60..<80: .orange
        default: .red
        }
    }
}

/// Visual sparkline showing category performance breakdown
struct CategorySparklineView: View {
    let categories: [CategoryMetrics]
    let height: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(categories) { metrics in
                Rectangle()
                    .fill(sparklineColor(for: metrics.passRate))
                    .frame(width: 6, height: height * metrics.passRate)
                    .accessibilityLabel("\(metrics.category.displayName): \(Int(metrics.passRate * 100))%")
            }
        }
    }

    private func sparklineColor(for rate: Double) -> Color {
        switch rate {
        case 0.8...: .green
        case 0.5..<0.8: .orange
        default: .red
        }
    }
}

struct MetricBadge: View {
    let label: String
    let value: Double
    let format: String

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value, format: .number.precision(.fractionLength(0)))
                .foregroundStyle(.primary)
            if !format.isEmpty && !format.hasPrefix("/") {
                Text(format)
                    .foregroundStyle(.tertiary)
            } else if format.hasPrefix("/") {
                Text(format)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    SuiteResultsView()
}

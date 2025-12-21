//
//  ScoreSummaryView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct ScoreSummaryView: View {
    let report: BenchmarkScoreReport
    let usage: TokenUsage?
    let provider: String?
    let model: String?

    @ScaledMetric private var spacing = 12

    var body: some View {
        GroupBox("Result") {
            VStack(alignment: .leading, spacing: spacing) {
                ScoreBadgeView(score: report.score)

                if let model {
                    Text("Model: \(model)")
                        .font(.subheadline)
                }

                if let provider {
                    Text("Provider: \(provider)")
                        .font(.subheadline)
                }

                if let usage {
                    HStack(spacing: spacing) {
                        Text("Prompt \(usage.prompt)")
                        Text("Completion \(usage.completion)")
                        Text("Total \(usage.total)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                ForEach(report.components) { component in
                    ProgressView(value: component.value, total: 1) {
                        Text(component.label)
                    } currentValueLabel: {
                        Text(component.value, format: .percent.precision(.fractionLength(0)))
                    }
                }
            }
        }
    }
}

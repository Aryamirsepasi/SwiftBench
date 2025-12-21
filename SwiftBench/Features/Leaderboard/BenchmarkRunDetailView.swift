//
//  BenchmarkRunDetailView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct BenchmarkRunDetailView: View {
    let run: BenchmarkRun

    @ScaledMetric private var spacing = 16
    @ScaledMetric private var cornerRadius = 16
    @ScaledMetric private var editorHeight = 220

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                ScoreBadgeView(score: run.score)

                GroupBox("Metadata") {
                    VStack(alignment: .leading, spacing: spacing) {
                        Text("Benchmark: \(run.benchmarkTitle)")
                        Text("Model: \(run.modelIdentifier)")
                        if let provider = run.provider {
                            Text("Provider: \(provider)")
                        }
                        Text("Created: \(run.createdAt, format: .dateTime)")
                        Text("Tokens: \(run.tokenTotal)")
                    }
                    .font(.subheadline)
                }

                GroupBox("Prompt") {
                    Text(run.prompt)
                        .font(.body.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Response") {
                    CodeTextView(text: run.response)
                        .frame(minHeight: editorHeight)
                        .clipShape(.rect(cornerRadius: cornerRadius))
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Run Details")
    }
}

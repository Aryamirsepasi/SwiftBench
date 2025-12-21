//
//  BenchmarkView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct BenchmarkView: View {
    @Environment(AppState.self) private var appState

    @ScaledMetric private var spacing = 16
    @ScaledMetric private var cornerRadius = 16
    @ScaledMetric private var editorHeight = 240

    var body: some View {
        let benchmark = appState.selectedBenchmark

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    Text(benchmark.title)
                        .font(.title2.bold())

                    GroupBox("Prompt") {
                        VStack(alignment: .leading, spacing: spacing) {
                            Text(benchmark.prompt)
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                PasteboardService.copy(benchmark.prompt)
                            } label: {
                                Label("Copy Prompt", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    GroupBox("Benchmark Code") {
                        VStack(alignment: .leading, spacing: spacing) {
                            CodeTextView(text: benchmark.benchmarkCode)
                                .frame(minHeight: editorHeight)
                                .clipShape(.rect(cornerRadius: cornerRadius))

                            Button {
                                PasteboardService.copy(benchmark.benchmarkCode)
                            } label: {
                                Label("Copy Code", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Benchmark")
        }
    }
}

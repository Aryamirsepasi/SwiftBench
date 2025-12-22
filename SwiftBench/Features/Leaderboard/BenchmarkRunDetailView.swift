//
//  BenchmarkRunDetailView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct BenchmarkRunDetailView: View {
    let run: BenchmarkRun

    @State private var showingPrompt = true
    @State private var showingResponse = true
    @State private var shareSheet: ShareSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutConstants.sectionSpacing) {
                ScoreBadgeView(score: run.score)

                metadataSection
                promptSection
                responseSection
            }
            .padding(LayoutConstants.contentPadding)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Run Details")
        #if os(iOS) || os(visionOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareSheet = ShareSheet(items: [shareText])
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $shareSheet) { sheet in
            ShareView(sheet: sheet)
        }
        #endif
    }

    private var shareText: String {
        """
        SwiftBench Result

        Score: \(run.score)
        Model: \(run.modelIdentifier)
        Tokens: \(run.tokenTotal)

        ---
        \(run.prompt)

        ---
        \(run.response)
        """
    }

    private var metadataSection: some View {
        DisclosureGroup("Metadata", isExpanded: .constant(true)) {
            VStack(alignment: .leading, spacing: LayoutConstants.smallPadding) {
                LabeledContent("Benchmark", value: run.benchmarkTitle)
                LabeledContent("Model", value: run.modelIdentifier)

                if let provider = run.provider {
                    LabeledContent("Provider", value: provider)
                }

                LabeledContent("Date") {
                    Text(run.createdAt, format: .dateTime)
                }

                LabeledContent("Tokens", value: "\(run.tokenTotal)")

                LabeledContent("Breakdown") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Prompt: \(run.tokenPrompt)")
                            .font(.caption2)
                        Text("Completion: \(run.tokenCompletion)")
                            .font(.caption2)
                    }
                }

                if let temp = run.temperature {
                    LabeledContent("Temperature") {
                        Text(temp, format: .number.precision(.fractionLength(1)))
                    }
                }

                if run.compilationSucceeded == false, let errors = run.compilationErrors {
                    LabeledContent("Compilation Errors", value: errors)
                }

                if let passed = run.testsPassed, let total = run.testsTotal {
                    LabeledContent("Tests") {
                        Text("\(passed) / \(total)")
                            .foregroundStyle(passed == total ? .green : .orange)
                    }
                }
            }
        }
    }

    private var promptSection: some View {
        DisclosureGroup("Prompt", isExpanded: $showingPrompt) {
            VStack(alignment: .trailing, spacing: LayoutConstants.controlSpacing) {
                Text(run.prompt)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    PasteboardService.copy(run.prompt)
                } label: {
                    Label("Copy Prompt", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var responseSection: some View {
        DisclosureGroup("Response", isExpanded: $showingResponse) {
            VStack(spacing: LayoutConstants.controlSpacing) {
                CodeTextView(text: run.response)
                    .frame(minHeight: LayoutConstants.minimumEditorHeight)
                    .clipShape(.rect(cornerRadius: LayoutConstants.cornerRadius))

                HStack(spacing: LayoutConstants.controlSpacing) {
                    Button {
                        PasteboardService.copy(run.response)
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    #if os(iOS) || os(visionOS)
                    Button {
                        shareSheet = ShareSheet(items: [run.response])
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    #endif
                }
            }
        }
    }
}


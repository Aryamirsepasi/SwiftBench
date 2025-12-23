//
//  TaskDetailView.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import SwiftUI

/// Detailed view of a single benchmark task.
struct TaskDetailView: View {
    let task: BenchmarkTask

    @State private var showingPrompt = true
    @State private var showingTestCode = false
    @State private var showingReference = false
    @State private var showingStyleRules = false
    @State private var shareSheet: ShareSheet?

    var body: some View {
        List {
            overviewSection
            promptSection
            testSection
            styleRulesSection
            referenceSection
        }
        .navigationTitle(task.title)
        #if os(iOS) || os(visionOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareSheet = ShareSheet(items: [task.prompt])
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

    // MARK: - Sections

    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("Category") {
                Label(task.category.displayName, systemImage: task.category.systemImage)
            }

            LabeledContent("Difficulty") {
                DifficultyBadge(difficulty: task.difficulty)
            }

            LabeledContent("Test Type") {
                if task.hasTests {
                    TestTypeBadge(testType: task.usesIOTesting ? .io : .xctest)
                } else {
                    Label("Compilation Only", systemImage: "hammer")
                        .foregroundStyle(.secondary)
                }
            }

            if let signature = task.expectedSignature {
                LabeledContent("Expected Signature") {
                    Text(signature)
                        .font(.caption.monospaced())
                }
            }
        }
    }

    private var promptSection: some View {
        Section {
            DisclosureGroup("Prompt", isExpanded: $showingPrompt) {
                VStack(alignment: .trailing, spacing: LayoutConstants.controlSpacing) {
                    Text(task.prompt)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: LayoutConstants.controlSpacing) {
                        Button {
                            PasteboardService.copy(task.prompt)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            shareSheet = ShareSheet(items: [task.prompt])
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var testSection: some View {
        if let pairs = task.inputOutputPairs, !pairs.isEmpty {
            Section("Input/Output Test Cases") {
                ForEach(pairs.indices, id: \.self) { index in
                    let pair = pairs[index]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Case \(index + 1)")
                                .font(.caption.weight(.medium))

                            Spacer()

                            if let desc = pair.description {
                                Text(desc)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Input")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(pair.input)
                                    .font(.caption.monospaced())
                            }

                            Spacer()

                            Image(systemName: "arrow.right")
                                .foregroundStyle(.tertiary)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Output")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(pair.expectedOutput)
                                    .font(.caption.monospaced())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }

        if let testCode = task.testCode, !testCode.isEmpty {
            Section {
                DisclosureGroup("XCTest Code", isExpanded: $showingTestCode) {
                    ScrollView(.horizontal) {
                        Text(testCode)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }

                    Button {
                        PasteboardService.copy(testCode)
                    } label: {
                        Label("Copy Test Code", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var styleRulesSection: some View {
        if !task.styleRules.isEmpty {
            Section {
                DisclosureGroup("Style Rules (\(task.styleRules.count))", isExpanded: $showingStyleRules) {
                    ForEach(task.styleRules, id: \.self) { ruleID in
                        if let rule = StyleRule.rule(for: ruleID) {
                            HStack {
                                Image(systemName: rule.isAntiPattern ? "xmark.circle" : "checkmark.circle")
                                    .foregroundStyle(rule.isAntiPattern ? .red : .green)

                                VStack(alignment: .leading) {
                                    Text(rule.name)
                                        .font(.subheadline)
                                    Text(rule.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text(ruleID)
                                .font(.caption.monospaced())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var referenceSection: some View {
        if let reference = task.referenceCode, !reference.isEmpty {
            Section {
                DisclosureGroup("Reference Implementation", isExpanded: $showingReference) {
                    ScrollView(.horizontal) {
                        Text(reference)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }

                    Button {
                        PasteboardService.copy(reference)
                    } label: {
                        Label("Copy Reference", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: BenchmarkSuite.v2.tasks.first!)
    }
}

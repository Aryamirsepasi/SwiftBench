//
//  RunBenchmarkView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftData
import SwiftUI

/// Main view for configuring and running benchmarks.
struct RunBenchmarkView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            #if os(macOS)
            macOSLayout
            #else
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
            #endif
        }
    }

    // MARK: - macOS Layout (Split View)

    #if os(macOS)
    private var macOSLayout: some View {
        HSplitView {
            mainContent
                .frame(minWidth: 400, idealWidth: 600)

            resultsSidebar
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        }
        .navigationTitle("Run Benchmark")
    }
    #endif

    // MARK: - iPad Layout (Horizontal Split)

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            mainContent
                .frame(maxWidth: .infinity)

            Divider()

            resultsSidebar
                .frame(width: 320)
        }
        .navigationTitle("Run Benchmark")
    }

    // MARK: - iPhone Layout (Vertical Stack)

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                connectionSection
                promptSection
                runControls
                outputSection

                if let report = appState.latestScoreReport {
                    ScoreSummaryView(
                        report: report,
                        usage: appState.latestUsage,
                        provider: appState.latestProvider,
                        model: appState.latestModelUsed
                    )
                }

                if let statusMessage = appState.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Run Benchmark")
    }

    // MARK: - Shared Components

    @ScaledMetric private var sectionSpacing = 16
    @ScaledMetric private var controlSpacing = 12
    @ScaledMetric private var cornerRadius = 16

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                connectionSection
                promptSection
                runControls
                outputSection

                if let statusMessage = appState.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }

    private var resultsSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                if let report = appState.latestScoreReport {
                    ScoreSummaryView(
                        report: report,
                        usage: appState.latestUsage,
                        provider: appState.latestProvider,
                        model: appState.latestModelUsed
                    )
                } else {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Run a benchmark to see results here.")
                    )
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(.background.secondary)
    }

    // MARK: - Sections

    private var connectionSection: some View {
        @Bindable var appState = appState

        return GroupBox("Connection") {
            VStack(alignment: .leading, spacing: controlSpacing) {
                #if os(iOS) || os(visionOS)
                SecureField("OpenRouter API Key", text: $appState.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                #else
                SecureField("OpenRouter API Key", text: $appState.apiKey)
                #endif

                HStack(spacing: controlSpacing) {
                    Button {
                        appState.saveAPIKey()
                    } label: {
                        Label("Save Key", systemImage: "key.fill")
                    }

                    Button(role: .destructive) {
                        appState.clearAPIKey()
                    } label: {
                        Label("Clear Key", systemImage: "key.slash")
                    }
                }

                Picker("Model", selection: $appState.modelPreset) {
                    ForEach(OpenRouterModelPreset.allCases) { preset in
                        Text(preset.rawValue)
                            .tag(preset)
                    }
                }
                .pickerStyle(.menu)

                if appState.modelPreset == .custom {
                    #if os(iOS) || os(visionOS)
                    TextField("Custom model identifier", text: $appState.customModelIdentifier)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #else
                    TextField("Custom model identifier", text: $appState.customModelIdentifier)
                    #endif
                }

                Text("Active model: \(appState.activeModelIdentifier)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var promptSection: some View {
        @Bindable var appState = appState

        return GroupBox("Prompt") {
            #if os(iOS) || os(visionOS)
            TextEditor(text: $appState.prompt)
                .font(.body.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: cornerRadius))
            #else
            TextEditor(text: $appState.prompt)
                .font(.body.monospaced())
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: cornerRadius))
            #endif
        }
    }

    private var runControls: some View {
        HStack(spacing: controlSpacing) {
            Button {
                appState.startBenchmark(using: modelContext)
            } label: {
                Label("Run Benchmark", systemImage: "bolt.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isRunning || appState.trimmedAPIKey.isEmpty || appState.activeModelIdentifier.isEmpty)

            Button(role: .cancel) {
                appState.cancelBenchmark()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!appState.isRunning)

            if appState.isRunning {
                ProgressView()
            }

            Spacer()
        }
    }

    private var outputSection: some View {
        GroupBox("Output") {
            ZStack(alignment: .topLeading) {
                CodeTextView(text: appState.streamedResponse)
                    .frame(minHeight: 200)
                    .clipShape(.rect(cornerRadius: cornerRadius))

                if appState.streamedResponse.isEmpty {
                    Text("Streaming output appears here.")
                        .foregroundStyle(.secondary)
                        .padding(.top, controlSpacing)
                        .padding(.leading, controlSpacing)
                }
            }
        }
    }
}

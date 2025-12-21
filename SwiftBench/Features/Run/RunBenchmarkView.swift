//
//  RunBenchmarkView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftData
import SwiftUI

struct RunBenchmarkView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @ScaledMetric private var sectionSpacing = 16
    @ScaledMetric private var controlSpacing = 12
    @ScaledMetric private var cornerRadius = 16
    @ScaledMetric private var editorHeight = 220

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    GroupBox("Connection") {
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

                    GroupBox("Prompt") {
                        #if os(iOS) || os(visionOS)
                        TextEditor(text: $appState.prompt)
                            .font(.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .frame(minHeight: editorHeight)
                            .clipShape(.rect(cornerRadius: cornerRadius))
                        #else
                        TextEditor(text: $appState.prompt)
                            .font(.body.monospaced())
                            .frame(minHeight: editorHeight)
                            .clipShape(.rect(cornerRadius: cornerRadius))
                        #endif
                    }

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
                    }

                    GroupBox("Output") {
                        ZStack(alignment: .topLeading) {
                            CodeTextView(text: appState.streamedResponse)
                                .frame(minHeight: editorHeight)
                                .clipShape(.rect(cornerRadius: cornerRadius))

                            if appState.streamedResponse.isEmpty {
                                Text("Streaming output appears here.")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, controlSpacing)
                                    .padding(.leading, controlSpacing)
                            }
                        }
                    }

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
    }
}

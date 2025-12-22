//
//  SuiteRunView.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import SwiftUI

/// View for configuring and running benchmark suites.
struct SuiteRunView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSuite: BenchmarkSuite = .v2
    @State private var runsPerTask = 1
    @State private var temperature = 0.7

    var body: some View {
        NavigationStack {
            Form {
                apiSection
                suiteSection
                configurationSection
                runSection
            }
            .formStyle(.grouped)
            .navigationTitle("Run Suite")
        }
    }

    // MARK: - Sections

    private var apiSection: some View {
        @Bindable var state = appState

        return Section("API Configuration") {
            SecureField("OpenRouter API Key", text: $state.apiKey)
                .textContentType(.password)

            HStack {
                Button("Save Key") {
                    appState.saveAPIKey()
                }
                .disabled(appState.apiKey.isEmpty)

                Button("Clear Key", role: .destructive) {
                    appState.clearAPIKey()
                }
                .disabled(appState.apiKey.isEmpty)
            }

            Picker("Model", selection: $state.modelPreset) {
                ForEach(OpenRouterModelPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            if appState.modelPreset == .custom {
                TextField("Custom Model ID", text: $state.customModelIdentifier)
            }
        }
    }

    private var suiteSection: some View {
        Section("Benchmark Suite") {
            Picker("Suite", selection: $selectedSuite) {
                ForEach(BenchmarkSuite.allSuites, id: \.id) { suite in
                    Text(suite.title).tag(suite)
                }
            }

            LabeledContent("Tasks", value: "\(selectedSuite.taskCount)")
            LabeledContent("Categories", value: "\(selectedSuite.categoryCounts.count)")

            DisclosureGroup("Task Breakdown") {
                ForEach(BenchmarkCategory.allCases) { category in
                    if let count = selectedSuite.categoryCounts[category], count > 0 {
                        HStack {
                            Label(category.displayName, systemImage: category.systemImage)
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var configurationSection: some View {
        Section("Run Configuration") {
            Stepper("Runs per task: \(runsPerTask)", value: $runsPerTask, in: 1...10)

            LabeledContent("Temperature") {
                Slider(value: $temperature, in: 0...2, step: 0.1)
                Text(temperature, format: .number.precision(.fractionLength(1)))
                    .monospacedDigit()
                    .frame(width: 40)
            }

            #if !os(macOS)
            Text("Code execution is only available on macOS. Results will use similarity-based scoring.")
                .font(.caption)
                .foregroundStyle(.secondary)
            #endif
        }
    }

    private var runSection: some View {
        Section {
            if appState.isSuiteRunning {
                SuiteProgressView()
            } else {
                Button {
                    Task {
                        await appState.runSuite(
                            selectedSuite,
                            runsPerTask: runsPerTask,
                            temperature: temperature,
                            using: modelContext
                        )
                    }
                } label: {
                    Label("Run Full Suite", systemImage: "play.fill")
                }
                .disabled(appState.apiKey.isEmpty || appState.modelIdentifier.isEmpty)

                if appState.apiKey.isEmpty {
                    Text("Enter your OpenRouter API key to run benchmarks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Progress View

/// Shows progress during a suite run.
struct SuiteProgressView: View {
    @Environment(AppState.self) private var appState

    @State private var animatedProgress: Double = 0
    @State private var startTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.sectionSpacing) {
            if let progress = appState.suiteRunProgress {
                // Main progress ring and percentage
                HStack(spacing: LayoutConstants.sectionSpacing) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: LayoutConstants.progressStrokeWidth)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: animatedProgress)
                            .stroke(.blue, style: StrokeStyle(lineWidth: LayoutConstants.progressStrokeWidth, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)
                            .animation(.linear(duration: 0.3), value: animatedProgress)

                        VStack(spacing: 2) {
                            Text("\(Int(progress.progress * 100))")
                                .font(.title2.bold())

                            Text("%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Running Suite")
                            .font(.headline)

                        if let currentTask = progress.currentTask {
                            Label(currentTask.title, systemImage: currentTask.category.systemImage)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }

                        Text("\(progress.completedTasks + 1) of \(progress.totalTasks) tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if progress.runsPerTask > 1 {
                            Text("Run \(progress.currentRunIndex + 1) of \(progress.runsPerTask) per task")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if let estimatedTime = estimatedTimeRemaining(progress: progress) {
                            Text(estimatedTime)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                #if os(macOS)
                if let phase = appState.executionPhase {
                    HStack {
                        ProgressView()
                            .controlSize(.small)

                        Text(phaseDescription(phase))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 4)
                }
                #endif
            }

            Button("Cancel", role: .destructive) {
                appState.cancelSuiteRun()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(LayoutConstants.contentPadding)
        .onAppear {
            startTime = Date()
        }
        .onChange(of: appState.suiteRunProgress) {
            if let progress = appState.suiteRunProgress {
                withAnimation(.linear(duration: 0.3)) {
                    animatedProgress = progress.progress
                }
            }
        }
    }

    private func estimatedTimeRemaining(progress: SuiteRunProgress) -> String? {
        guard let startTime = startTime,
              progress.completedTasks > 0 else { return nil }

        let elapsedTime = Date().timeIntervalSince(startTime)
        let avgTimePerTask = elapsedTime / Double(progress.completedTasks)
        let remainingTasks = progress.totalTasks - progress.completedTasks
        let estimatedRemaining = avgTimePerTask * Double(remainingTasks)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.minute, .second]
        return "~" + (formatter.string(from: TimeInterval(estimatedRemaining)) ?? "")
    }

    #if os(macOS)
    private func phaseDescription(_ phase: TestExecutionService.ExecutionPhase) -> String {
        switch phase {
        case .idle:
            "Ready"
        case .creatingPackage:
            "Creating test package..."
        case .compiling:
            "Compiling..."
        case .runningTests:
            "Running tests..."
        case .parsingResults:
            "Parsing results..."
        case .cleaningUp:
            "Cleaning up..."
        }
    }
    #endif
}

#Preview {
    SuiteRunView()
        .environment(AppState())
}

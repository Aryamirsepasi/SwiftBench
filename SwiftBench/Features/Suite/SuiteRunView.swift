//
//  SuiteRunView.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import SwiftData
import SwiftUI

/// View for configuring and running benchmark suites or single tasks.
struct SuiteRunView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedSuite: BenchmarkSuite = .v2
    @State private var runsPerTask = 1
    @State private var temperature = 0.7
    @State private var isConnectionExpanded = false
    @State private var showScoreDetails = false
    @State private var runMode: RunMode = .suite

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
                .frame(
                    minWidth: LayoutConstants.compactSidebarWidth,
                    idealWidth: LayoutConstants.idealSidebarWidth,
                    maxWidth: LayoutConstants.maxSidebarWidth
                )
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
                .frame(width: LayoutConstants.idealSidebarWidth)
        }
        .navigationTitle("Run Benchmark")
    }

    // MARK: - iPhone Layout (Vertical Stack)

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutConstants.sectionSpacing) {
                runModeSelector
                apiSection

                if runMode == .single {
                    singleTaskPromptSection
                    singleTaskRunControls
                } else {
                    suiteSection
                    configurationSection
                    suiteRunControls
                }

                if !appState.streamedResponse.isEmpty {
                    outputSection
                }

                if let report = appState.latestScoreReport {
                    VStack(spacing: LayoutConstants.sectionSpacing) {
                        ScoreBadgeView(score: report.score, showDetails: $showScoreDetails)

                        if showScoreDetails {
                            ScoreSummaryView(
                                report: report,
                                usage: appState.latestUsage,
                                provider: appState.latestProvider,
                                model: appState.latestModelUsed
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
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

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutConstants.sectionSpacing) {
                runModeSelector
                apiSection

                if runMode == .single {
                    singleTaskPromptSection
                    singleTaskRunControls
                } else {
                    suiteSection
                    configurationSection
                    suiteRunControls
                }

                if !appState.streamedResponse.isEmpty {
                    outputSection
                }

                if let statusMessage = appState.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(LayoutConstants.contentPadding)
        }
        .scrollIndicators(.hidden)
    }

    private var resultsSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutConstants.sectionSpacing) {
                if let report = appState.latestScoreReport {
                    VStack(spacing: LayoutConstants.sectionSpacing) {
                        ScoreBadgeView(score: report.score, showDetails: $showScoreDetails)

                        if showScoreDetails {
                            ScoreSummaryView(
                                report: report,
                                usage: appState.latestUsage,
                                provider: appState.latestProvider,
                                model: appState.latestModelUsed
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Run a benchmark to see results here.")
                    )
                }
            }
            .padding(LayoutConstants.contentPadding)
        }
        .scrollIndicators(.hidden)
        .background(.background.secondary)
    }

    // MARK: - Run Mode Selector

    private var runModeSelector: some View {
        Picker("Run Mode", selection: $runMode) {
            ForEach(RunMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, LayoutConstants.sectionSpacing)
    }

    // MARK: - Sections

    private var apiSection: some View {
        @Bindable var state = appState

        let isConfigured = !state.trimmedAPIKey.isEmpty && !state.activeModelIdentifier.isEmpty

        return GroupBox {
            if isConfigured && !isConnectionExpanded {
                // Compact view when configured
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready to Run")
                            .font(.headline)
                        Text(state.activeModelIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Configure") {
                        withAnimation(.spring()) {
                            isConnectionExpanded = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // Expanded view
                DisclosureGroup("Connection", isExpanded: $isConnectionExpanded) {
                    VStack(alignment: .leading, spacing: LayoutConstants.controlSpacing) {
                        #if os(iOS) || os(visionOS)
                        SecureField("OpenRouter API Key", text: $state.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.password)
                        #else
                        SecureField("OpenRouter API Key", text: $state.apiKey)
                        #endif

                        HStack(spacing: LayoutConstants.controlSpacing) {
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

                        Picker("Model", selection: $state.modelPreset) {
                            ForEach(OpenRouterModelPreset.allCases) { preset in
                                Text(preset.displayName)
                                    .tag(preset)
                            }
                        }
                        .pickerStyle(.menu)

                        if state.modelPreset == .custom {
                            #if os(iOS) || os(visionOS)
                            TextField("Custom model identifier", text: $state.customModelIdentifier)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            #else
                            TextField("Custom model identifier", text: $state.customModelIdentifier)
                            #endif
                        }

                        Text("Active model: \(state.activeModelIdentifier)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var singleTaskPromptSection: some View {
        @Bindable var state = appState

        return GroupBox("Prompt") {
            #if os(iOS) || os(visionOS)
            TextEditor(text: $state.prompt)
                .font(.body.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: LayoutConstants.cornerRadius))
            #else
            TextEditor(text: $state.prompt)
                .font(.body.monospaced())
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: LayoutConstants.cornerRadius))
            #endif
        }
    }

    private var suiteSection: some View {
        Section("Benchmark Suite") {
            Picker("Suite", selection: $selectedSuite) {
                ForEach(BenchmarkSuite.allSuites, id: \.id) { suite in
                    Text(suite.title)
                        .tag(suite)
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

    private var singleTaskRunControls: some View {
        HStack(spacing: LayoutConstants.controlSpacing) {
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

    private var suiteRunControls: some View {
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

    private var outputSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Output")
                        .font(.headline)

                    Spacer()

                    if appState.isRunning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)

                            Text("Streaming...")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let usage = appState.latestUsage {
                                Text("\(usage.total) tokens")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } else if !appState.streamedResponse.isEmpty {
                        if let usage = appState.latestUsage {
                            Text("\(usage.total) tokens")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ZStack(alignment: .topLeading) {
                    CodeTextView(text: appState.streamedResponse)
                        .frame(minHeight: LayoutConstants.minimumEditorHeight)
                        .clipShape(.rect(cornerRadius: LayoutConstants.cornerRadius))

                    if appState.streamedResponse.isEmpty {
                        Text("Streaming output appears here.")
                            .foregroundStyle(.secondary)
                            .padding(.top, LayoutConstants.controlSpacing)
                            .padding(.leading, LayoutConstants.controlSpacing)
                    }
                }
            }
        }
    }
}

// MARK: - Run Mode

enum RunMode: String, CaseIterable, Identifiable {
    case single = "Single Task"
    case suite = "Full Suite"
    
    var id: String { rawValue }
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

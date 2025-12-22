//
//  AppState.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import AIProxy
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppState {
    // MARK: - API Configuration

    var apiKey: String
    var modelPreset: OpenRouterModelPreset
    var customModelIdentifier: String

    // MARK: - Single Benchmark State (Legacy)

    var prompt: String
    var selectedBenchmark: BenchmarkSpec
    var streamedResponse: String
    var latestScoreReport: BenchmarkScoreReport?
    var latestUsage: TokenUsage?
    var latestProvider: String?
    var latestModelUsed: String?
    var statusMessage: String?
    var isRunning: Bool

    // MARK: - Suite Run State

    var isSuiteRunning: Bool = false
    var suiteRunProgress: SuiteRunProgress?
    var latestSuiteResult: SuiteRunResult?

    #if os(macOS)
    var executionPhase: TestExecutionService.ExecutionPhase?

    @ObservationIgnored
    private let executionService = TestExecutionService()
    #endif

    @ObservationIgnored
    private var runTask: Task<Void, Never>?

    @ObservationIgnored
    private var suiteRunTask: Task<Void, Never>?

    @ObservationIgnored
    private let scorer = BenchmarkScorer()

    init() {
        let benchmark = BenchmarkSpec.swiftBench
        apiKey = KeychainStore.loadAPIKey() ?? ""
        modelPreset = .devstral2512
        customModelIdentifier = ""
        selectedBenchmark = benchmark
        prompt = benchmark.prompt
        streamedResponse = ""
        latestScoreReport = nil
        latestUsage = nil
        latestProvider = nil
        latestModelUsed = nil
        statusMessage = nil
        isRunning = false
    }

    // MARK: - Computed Properties

    var modelIdentifier: String {
        activeModelIdentifier
    }

    var activeModelIdentifier: String {
        if let presetModelID = modelPreset.modelID {
            return presetModelID
        }

        return customModelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func saveAPIKey() {
        guard !trimmedAPIKey.isEmpty else {
            statusMessage = "Enter an API key before saving."
            return
        }

        do {
            try KeychainStore.saveAPIKey(trimmedAPIKey)
            statusMessage = "API key saved to Keychain."
        } catch {
            statusMessage = "Failed to save API key."
        }
    }

    func clearAPIKey() {
        do {
            try KeychainStore.deleteAPIKey()
            apiKey = ""
            statusMessage = "API key removed."
        } catch {
            statusMessage = "Failed to remove API key."
        }
    }

    func startBenchmark(using modelContext: ModelContext) {
        guard !isRunning else { return }
        statusMessage = nil
        streamedResponse = ""
        latestScoreReport = nil
        latestUsage = nil
        latestProvider = nil
        latestModelUsed = nil

        runTask?.cancel()
        runTask = Task {
            await runBenchmark(using: modelContext)
        }
    }

    func cancelBenchmark() {
        runTask?.cancel()
        runTask = nil
        isRunning = false
        statusMessage = "Run canceled."
    }

    private func runBenchmark(using modelContext: ModelContext) async {
        let apiKeySnapshot = trimmedAPIKey
        let modelIDSnapshot = activeModelIdentifier
        let promptSnapshot = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let benchmark = selectedBenchmark

        guard !apiKeySnapshot.isEmpty else {
            statusMessage = "Add your OpenRouter API key first."
            return
        }

        guard !modelIDSnapshot.isEmpty else {
            statusMessage = "Select or enter a model identifier."
            return
        }

        guard !promptSnapshot.isEmpty else {
            statusMessage = "Enter a prompt to benchmark."
            return
        }

        isRunning = true
        defer {
            isRunning = false
        }

        do {
            let openRouterService = AIProxy.openRouterDirectService(
                unprotectedAPIKey: apiKeySnapshot
            )

            let requestBody = OpenRouterChatCompletionRequestBody(
                messages: [.user(content: .text(promptSnapshot))],
                models: [modelIDSnapshot],
                route: .fallback
            )

            let stream = try await openRouterService.streamingChatCompletionRequest(body: requestBody)
            for try await chunk in stream {
                if Task.isCancelled {
                    statusMessage = "Run canceled."
                    return
                }

                if let delta = chunk.choices.first?.delta.content {
                    streamedResponse.append(delta)
                }

                if let usage = chunk.usage {
                    latestUsage = TokenUsage(
                        prompt: usage.promptTokens ?? 0,
                        completion: usage.completionTokens ?? 0,
                        total: usage.totalTokens ?? 0
                    )
                }

                if let provider = chunk.provider {
                    latestProvider = provider
                }

                if let model = chunk.model {
                    latestModelUsed = model
                }
            }

            if Task.isCancelled {
                statusMessage = "Run canceled."
                return
            }

            let extractedCode = CodeExtractor.extract(from: streamedResponse)
            let report = scorer.score(generated: extractedCode, benchmark: benchmark.benchmarkCode)
            latestScoreReport = report

            let usage = latestUsage ?? TokenUsage(prompt: 0, completion: 0, total: 0)
            let run = BenchmarkRun(
                benchmarkID: benchmark.id,
                benchmarkTitle: benchmark.title,
                modelIdentifier: modelIDSnapshot,
                provider: latestProvider,
                prompt: promptSnapshot,
                response: extractedCode,
                score: report.score,
                tokenPrompt: usage.prompt,
                tokenCompletion: usage.completion,
                tokenTotal: usage.total
            )
            modelContext.insert(run)

            do {
                try modelContext.save()
            } catch {
                statusMessage = "Run saved, but SwiftData could not persist it."
            }
        } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
            statusMessage = "OpenRouter error \(statusCode): \(responseBody)"
        } catch {
            statusMessage = "Streaming failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Suite Run Methods

    /// Runs a complete benchmark suite.
    func runSuite(
        _ suite: BenchmarkSuite,
        runsPerTask: Int,
        temperature: Double,
        using modelContext: ModelContext
    ) async {
        guard !isSuiteRunning else { return }

        isSuiteRunning = true
        latestSuiteResult = nil
        suiteRunProgress = SuiteRunProgress(
            totalTasks: suite.taskCount,
            completedTasks: 0,
            currentTask: nil,
            currentRunIndex: 0,
            runsPerTask: runsPerTask
        )

        suiteRunTask?.cancel()
        suiteRunTask = Task {
            await performSuiteRun(
                suite: suite,
                runsPerTask: runsPerTask,
                temperature: temperature,
                using: modelContext
            )
        }
    }

    /// Cancels the current suite run.
    func cancelSuiteRun() {
        suiteRunTask?.cancel()
        suiteRunTask = nil
        isSuiteRunning = false
        suiteRunProgress = nil
        #if os(macOS)
        executionPhase = nil
        #endif
        statusMessage = "Suite run canceled."
    }

    private func performSuiteRun(
        suite: BenchmarkSuite,
        runsPerTask: Int,
        temperature: Double,
        using modelContext: ModelContext
    ) async {
        var allRuns: [BenchmarkRun] = []
        let startTime = Date()
        var totalTokens = 0

        defer {
            isSuiteRunning = false
            suiteRunProgress = nil
            #if os(macOS)
            executionPhase = nil
            #endif
        }

        for (taskIndex, task) in suite.tasks.enumerated() {
            if Task.isCancelled { return }

            for runIndex in 0..<runsPerTask {
                if Task.isCancelled { return }

                // Update progress
                suiteRunProgress = SuiteRunProgress(
                    totalTasks: suite.taskCount,
                    completedTasks: taskIndex,
                    currentTask: task,
                    currentRunIndex: runIndex,
                    runsPerTask: runsPerTask
                )

                // Run the task
                if let run = await runSingleTask(
                    task: task,
                    suite: suite,
                    runIndex: runIndex,
                    temperature: temperature,
                    using: modelContext
                ) {
                    allRuns.append(run)
                    totalTokens += run.tokenTotal
                }
            }
        }

        // Calculate aggregate metrics
        let metrics = AggregateMetricsCalculator.calculate(
            from: allRuns,
            suite: suite,
            kValue: runsPerTask
        )

        // Create suite result
        let result = SuiteRunResult(
            suiteID: suite.id,
            suiteVersion: suite.version,
            suiteTitle: suite.title,
            modelIdentifier: activeModelIdentifier,
            provider: latestProvider,
            passAt1: metrics.passAt1,
            passAtK: metrics.passAtK,
            kValue: runsPerTask,
            meanScore: metrics.meanScore,
            scoreVariance: metrics.variance,
            meanStyleScore: metrics.meanStyleScore,
            categoryResults: metrics.categoryMetrics,
            totalTokensUsed: totalTokens,
            estimatedCost: nil,
            temperature: temperature,
            totalTasks: suite.taskCount,
            passedTasks: metrics.passedTasks,
            totalExecutionTime: Date().timeIntervalSince(startTime)
        )

        modelContext.insert(result)
        try? modelContext.save()

        latestSuiteResult = result
    }

    private func runSingleTask(
        task: BenchmarkTask,
        suite: BenchmarkSuite,
        runIndex: Int,
        temperature: Double,
        using modelContext: ModelContext
    ) async -> BenchmarkRun? {
        let apiKeySnapshot = trimmedAPIKey
        let modelIDSnapshot = activeModelIdentifier

        guard !apiKeySnapshot.isEmpty, !modelIDSnapshot.isEmpty else {
            return nil
        }

        do {
            // Call OpenRouter API
            let openRouterService = AIProxy.openRouterDirectService(
                unprotectedAPIKey: apiKeySnapshot
            )

            let requestBody = OpenRouterChatCompletionRequestBody(
                messages: [.user(content: .text(task.prompt))],
                models: [modelIDSnapshot],
                route: .fallback
            )

            var response = ""
            var usage: TokenUsage?
            var provider: String?

            let stream = try await openRouterService.streamingChatCompletionRequest(body: requestBody)
            for try await chunk in stream {
                if Task.isCancelled { return nil }

                if let delta = chunk.choices.first?.delta.content {
                    response.append(delta)
                }

                if let chunkUsage = chunk.usage {
                    usage = TokenUsage(
                        prompt: chunkUsage.promptTokens ?? 0,
                        completion: chunkUsage.completionTokens ?? 0,
                        total: chunkUsage.totalTokens ?? 0
                    )
                }

                if let chunkProvider = chunk.provider {
                    provider = chunkProvider
                    latestProvider = chunkProvider
                }
            }

            let extractedCode = CodeExtractor.extract(from: response)
            let tokenUsage = usage ?? TokenUsage(prompt: 0, completion: 0, total: 0)

            // Calculate similarity score (fallback)
            let similarityScore: Double
            if let reference = task.referenceCode {
                let report = scorer.score(generated: extractedCode, benchmark: reference)
                similarityScore = report.score
            } else {
                similarityScore = 0
            }

            // Execute tests (macOS only)
            #if os(macOS)
            let executionResult: ExecutionResult?
            if task.hasTests {
                executionPhase = executionService.currentPhase
                executionResult = try? await executionService.execute(
                    generatedCode: extractedCode,
                    task: task
                )
                executionPhase = nil

                // Log detailed execution results for debugging
                if let result = executionResult {
                    if !result.compilationSucceeded {
                        statusMessage = "Compilation failed for task '\(task.title)': \(result.compilationErrors ?? "Unknown error")"
                    } else if !result.allTestsPassed {
                        statusMessage = "Tests failed for task '\(task.title)': \(result.testsPassed ?? 0)/\(result.testsTotal ?? 0) passed"
                    } else {
                        statusMessage = "Task '\(task.title)' passed all tests"
                    }
                }
            } else {
                executionResult = nil
            }

            let run = BenchmarkRun(
                benchmarkID: suite.id,
                benchmarkTitle: suite.title,
                taskID: task.id,
                taskCategory: task.category.rawValue,
                modelIdentifier: modelIDSnapshot,
                provider: provider,
                prompt: task.prompt,
                response: extractedCode,
                score: similarityScore,
                compilationSucceeded: executionResult?.compilationSucceeded,
                compilationErrors: executionResult?.compilationErrors,
                compilationOutput: executionResult?.compilationOutput,
                testsPassed: executionResult?.testsPassed,
                testsTotal: executionResult?.testsTotal,
                testOutput: executionResult?.testOutput,
                executionTimeSeconds: executionResult?.executionTime,
                styleScore: executionResult?.styleScore,
                styleViolations: executionResult?.styleViolations ?? [],
                temperature: temperature,
                runIndex: runIndex,
                tokenPrompt: tokenUsage.prompt,
                tokenCompletion: tokenUsage.completion,
                tokenTotal: tokenUsage.total
            )
            #else
            let run = BenchmarkRun(
                benchmarkID: suite.id,
                benchmarkTitle: suite.title,
                taskID: task.id,
                taskCategory: task.category.rawValue,
                modelIdentifier: modelIDSnapshot,
                provider: provider,
                prompt: task.prompt,
                response: extractedCode,
                score: similarityScore,
                compilationSucceeded: nil,
                compilationErrors: nil,
                compilationOutput: nil,
                testsPassed: nil,
                testsTotal: nil,
                testOutput: nil,
                executionTimeSeconds: nil,
                styleScore: nil,
                styleViolations: [],
                temperature: temperature,
                runIndex: runIndex,
                tokenPrompt: tokenUsage.prompt,
                tokenCompletion: tokenUsage.completion,
                tokenTotal: tokenUsage.total
            )
            #endif

            modelContext.insert(run)
            try? modelContext.save()

            return run

        } catch {
            statusMessage = "Task failed: \(error.localizedDescription)"
            return nil
        }
    }
}


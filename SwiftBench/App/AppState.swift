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
    var apiKey: String
    var modelPreset: OpenRouterModelPreset
    var customModelIdentifier: String
    var prompt: String
    var selectedBenchmark: BenchmarkSpec
    var streamedResponse: String
    var latestScoreReport: BenchmarkScoreReport?
    var latestUsage: TokenUsage?
    var latestProvider: String?
    var latestModelUsed: String?
    var statusMessage: String?
    var isRunning: Bool

    @ObservationIgnored
    private var runTask: Task<Void, Never>?

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
}

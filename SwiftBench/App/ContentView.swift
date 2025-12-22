//
//  ContentView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: [SortDescriptor(\SuiteRunResult.createdAt, order: .reverse)])
    private var suiteResults: [SuiteRunResult]

    @Query(sort: [SortDescriptor(\BenchmarkRun.createdAt, order: .reverse)])
    private var recentRuns: [BenchmarkRun]

    @State private var hasSeenResults = false
    @State private var lastResultsCount = 0

    var body: some View {
        TabView {
            Tab("Suite", systemImage: "list.bullet.clipboard") {
                SuiteRunView()
            }

            Tab("Results", systemImage: "chart.bar.doc.horizontal") {
                SuiteResultsView()
            }
            .badge(resultsBadge ?? 0)

            Tab("Tasks", systemImage: "doc.text.magnifyingglass") {
                TaskBrowserView()
            }

            Tab("Leaderboard", systemImage: "list.number") {
                LeaderboardView()
            }
        }
        .onChange(of: suiteResults.count) { oldValue, newValue in
            if newValue > lastResultsCount && hasSeenResults {
                lastResultsCount = newValue
            }
        }
    }

    private var resultsBadge: Int? {
        let unseenCount = suiteResults.count - lastResultsCount
        return unseenCount > 0 ? unseenCount : nil
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [BenchmarkRun.self, SuiteRunResult.self], inMemory: true)
}

//
//  ContentView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Run", systemImage: "bolt.fill") {
                RunBenchmarkView()
            }

            Tab("Leaderboard", systemImage: "list.number") {
                LeaderboardView()
            }

            Tab("Benchmark", systemImage: "doc.text.magnifyingglass") {
                BenchmarkView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: BenchmarkRun.self, inMemory: true)
}

//
//  LeaderboardView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftData
import SwiftUI

struct LeaderboardView: View {
    @Query(
        sort: [
            SortDescriptor(\BenchmarkRun.score, order: .reverse),
            SortDescriptor(\BenchmarkRun.createdAt, order: .reverse),
        ]
    )
    private var runs: [BenchmarkRun]

    var body: some View {
        NavigationStack {
            Group {
                if runs.isEmpty {
                    ContentUnavailableView(
                        "No Benchmark Runs",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Run a benchmark to see results on the leaderboard.")
                    )
                } else {
                    List(runs) { run in
                        NavigationLink(value: run) {
                            LeaderboardRowView(run: run)
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationDestination(for: BenchmarkRun.self) { run in
                BenchmarkRunDetailView(run: run)
            }
        }
    }
}

//
//  LeaderboardView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftData
import SwiftUI

/// Displays a ranked leaderboard of all benchmark runs sorted by score.
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
                    List(runs.enumerated(), id: \.element.id) { index, run in
                        NavigationLink(value: run) {
                            LeaderboardRowView(rank: index + 1, run: run)
                        }
                    }
                    #if os(iOS) || os(visionOS)
                    .listStyle(.insetGrouped)
                    #endif
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

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

    @State private var selectedFilter: LeaderboardFilter = .all
    @State private var selectedSort: LeaderboardSort = .score

    var filteredAndSortedRuns: [BenchmarkRun] {
        let filtered = selectedFilter.filter(runs)
        return selectedSort.sort(filtered)
    }

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
                    List {
                        filterSortSection

                        if filteredAndSortedRuns.isEmpty {
                            ContentUnavailableView.search(text: "")
                        } else {
                            ForEach(Array(filteredAndSortedRuns.enumerated()), id: \.element.id) { index, run in
                                NavigationLink(value: run) {
                                    LeaderboardRowView(rank: index + 1, run: run)
                                }
                            }
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

    private var filterSortSection: some View {
        Section {
            HStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(LeaderboardFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Sort", selection: $selectedSort) {
                    ForEach(LeaderboardSort.allCases) { sort in
                        Text(sort.displayName).tag(sort)
                    }
                }
                .pickerStyle(.menu)
            }
            .labelsHidden()
        }
    }
}

// MARK: - Filter Options

enum LeaderboardFilter: CaseIterable, Identifiable {
    case all
    case recent
    case top10

    var id: String {
        switch self {
        case .all: "all"
        case .recent: "recent"
        case .top10: "top10"
        }
    }

    var displayName: String {
        switch self {
        case .all: "All"
        case .recent: "Recent"
        case .top10: "Top 10"
        }
    }

    func filter(_ runs: [BenchmarkRun]) -> [BenchmarkRun] {
        switch self {
        case .all:
            return runs
        case .recent:
            if let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) {
                return runs.filter { $0.createdAt >= weekAgo }
            }
            return runs
        case .top10:
            return Array(runs.prefix(10))
        }
    }
}

enum LeaderboardSort: CaseIterable, Identifiable {
    case score
    case date
    case tokens

    var id: String {
        switch self {
        case .score: "score"
        case .date: "date"
        case .tokens: "tokens"
        }
    }

    var displayName: String {
        switch self {
        case .score: "Score"
        case .date: "Date"
        case .tokens: "Tokens"
        }
    }

    func sort(_ runs: [BenchmarkRun]) -> [BenchmarkRun] {
        switch self {
        case .score:
            return runs.sorted { $0.score > $1.score }
        case .date:
            return runs.sorted { $0.createdAt > $1.createdAt }
        case .tokens:
            return runs.sorted { $0.tokenTotal > $1.tokenTotal }
        }
    }
}

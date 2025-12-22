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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter: LeaderboardFilter = .all
    @State private var selectedSort: LeaderboardSort = .score
    @State private var shareSheet: ShareSheet?

    // Alert states
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    @State private var runToDelete: BenchmarkRun?

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
                                #if os(iOS) || os(visionOS)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        runToDelete = run
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                                #endif
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export CSV", systemImage: "square.and.arrow.down")
                        }

                        Divider()

                        Button {
                            showingResetAlert = true
                        } label: {
                            Label("Reset Leaderboard", systemImage: "trash")
                        }
                        .foregroundStyle(.red)
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Run", isPresented: $showingDeleteAlert, presenting: runToDelete) { run in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteRun(run)
                }
            } message: { run in
                Text("Are you sure you want to delete the run by \"\(run.modelIdentifier)\"?")
            }
            .alert("Reset Leaderboard", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetLeaderboard()
                }
            } message: {
                Text("Are you sure you want to delete all \(runs.count) benchmark runs? This action cannot be undone.")
            }
            #if os(iOS) || os(visionOS)
            .sheet(item: $shareSheet) { sheet in
                ShareView(sheet: sheet)
            }
            #elseif os(macOS)
            .sheet(item: $shareSheet) { sheet in
                ShareView(sheet: sheet)
            }
            #endif
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

    // MARK: - Actions

    /// Deletes a single benchmark run.
    private func deleteRun(_ run: BenchmarkRun) {
        withAnimation {
            modelContext.delete(run)
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete run: \(error)")
            }
        }
    }

    /// Resets the leaderboard by deleting all benchmark runs.
    private func resetLeaderboard() {
        withAnimation {
            for run in runs {
                modelContext.delete(run)
            }
            do {
                try modelContext.save()
            } catch {
                print("Failed to reset leaderboard: \(error)")
            }
        }
    }

    /// Exports the leaderboard data as a CSV file.
    private func exportCSV() {
        let csvData = LeaderboardExporter.exportCSV(runs: filteredAndSortedRuns)
        let filename = LeaderboardExporter.generateFilename()

        guard let csvURL = createCSVFileURL(filename: filename, data: csvData) else {
            return
        }

        shareSheet = ShareSheet(items: [csvURL])
    }

    /// Creates a temporary file URL for the CSV data.
    private func createCSVFileURL(filename: String, data: String) -> URL? {
        guard let data = data.data(using: .utf8) else {
            return nil
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appending(path: filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
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

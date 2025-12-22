//
//  LeaderboardExporter.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

/// Service for exporting leaderboard data to CSV format.
enum LeaderboardExporter {

    /// Generates CSV data from an array of benchmark runs.
    /// - Parameter runs: The benchmark runs to export
    /// - Returns: CSV string with properly formatted data
    static func exportCSV(runs: [BenchmarkRun]) -> String {
        var csv = ""

        // Header row
        csv += "Rank,Model,Score,Tokens,Date,Temperature,Pass Rate\n"

        // Data rows
        for (index, run) in runs.enumerated() {
            csv += buildCSVRow(rank: index + 1, run: run)
        }

        return csv
    }

    /// Builds a single CSV row with proper escaping.
    private static func buildCSVRow(rank: Int, run: BenchmarkRun) -> String {
        var columns: [String] = []

        columns.append(escapeCSV(String(rank)))
        columns.append(escapeCSV(run.modelIdentifier))
        columns.append(escapeCSV(formatScore(run.score)))
        columns.append(escapeCSV(String(run.tokenTotal)))
        columns.append(escapeCSV(formatDate(run.createdAt)))

        if let temperature = run.temperature {
            columns.append(escapeCSV(formatTemperature(temperature)))
        } else {
            columns.append("")
        }

        if let passed = run.testsPassed, let total = run.testsTotal, total > 0 {
            columns.append(escapeCSV(formatPassRate(passed: passed, total: total)))
        } else {
            columns.append("")
        }

        return columns.joined(separator: ",") + "\n"
    }

    /// Escapes a CSV field by wrapping in quotes if needed.
    private static func escapeCSV(_ field: String) -> String {
        // If field contains comma, quote, or newline, wrap in quotes and escape quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacing("\"", with: "\"\""))\""
        }
        return field
    }

    /// Formats a score value for CSV.
    private static func formatScore(_ score: Double) -> String {
        String(format: "%.2f", score)
    }

    /// Formats a date for CSV.
    private static func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    /// Formats a temperature value for CSV.
    private static func formatTemperature(_ temperature: Double) -> String {
        String(format: "%.2f", temperature)
    }

    /// Formats a pass rate for CSV.
    private static func formatPassRate(passed: Int, total: Int) -> String {
        let rate = Double(passed) / Double(total)
        return String(format: "%.2f", rate * 100) + "%"
    }

    /// Generates a filename for the CSV export.
    /// - Returns: Filename with timestamp
    static func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "swiftbench_leaderboard_\(timestamp).csv"
    }
}


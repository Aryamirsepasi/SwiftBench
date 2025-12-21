//
//  LeaderboardRowView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

/// Displays a single leaderboard entry with rank, model info, and score.
struct LeaderboardRowView: View {
    let rank: Int
    let run: BenchmarkRun

    @ScaledMetric private var rankWidth = 36
    @ScaledMetric private var scoreWidth = 56
    @ScaledMetric private var spacing = 12

    var body: some View {
        HStack(spacing: spacing) {
            rankBadge
            modelInfo
            Spacer(minLength: spacing)
            scoreBadge
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(run.modelIdentifier), rank \(rank), score \(Int(run.score))")
    }

    // MARK: - Private Views

    private var rankBadge: some View {
        Text("#\(rank)")
            .font(.headline.monospacedDigit())
            .foregroundStyle(rankColor)
            .frame(width: rankWidth, alignment: .leading)
    }

    private var modelInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(run.modelIdentifier)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                Label("\(run.tokenTotal)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(run.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var scoreBadge: some View {
        Text(run.score, format: .number.precision(.fractionLength(1)))
            .font(.title3.bold().monospacedDigit())
            .foregroundStyle(scoreColor)
            .frame(minWidth: scoreWidth, alignment: .trailing)
    }

    // MARK: - Private Computed Properties

    private var rankColor: Color {
        switch rank {
        case 1: .yellow
        case 2: .gray
        case 3: .orange
        default: .secondary
        }
    }

    private var scoreColor: Color {
        switch run.score {
        case 80...: .green
        case 60..<80: .orange
        default: .red
        }
    }
}

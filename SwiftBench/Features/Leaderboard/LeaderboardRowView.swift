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
        .listRowBackground(backgroundForRank(rank))
    }

    // MARK: - Private Views

    private var rankBadge: some View {
        Group {
            if rank <= 3 {
                ZStack {
                    medalBackground(for: rank)
                        .frame(width: rankWidth, height: rankWidth)

                    medalIcon(for: rank)
                        .font(.caption.weight(.bold))
                }
            } else {
                Text("#\(rank)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: rankWidth, alignment: .leading)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var modelInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(run.modelIdentifier)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 12) {
                Text("\(run.tokenTotal) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

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
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(scoreColor.opacity(0.15), in: .capsule)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func medalBackground(for rank: Int) -> some View {
        switch rank {
        case 1:
            Circle()
                .fill(.yellow.opacity(0.2))
        case 2:
            Circle()
                .fill(.gray.opacity(0.2))
        case 3:
            Circle()
                .fill(.orange.opacity(0.2))
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func medalIcon(for rank: Int) -> some View {
        switch rank {
        case 1:
            Image(systemName: "1.circle.fill")
                .foregroundStyle(.yellow)
        case 2:
            Image(systemName: "2.circle.fill")
                .foregroundStyle(.gray)
        case 3:
            Image(systemName: "3.circle.fill")
                .foregroundStyle(.orange)
        default:
            EmptyView()
        }
    }

    // MARK: - Private Computed Properties

    private func backgroundForRank(_ rank: Int) -> Color {
        if rank <= 3 {
            return Color.secondary.opacity(0.1)
        }
        return Color.clear
    }

    private var scoreColor: Color {
        switch run.score {
        case 90...: .green
        case 80..<90: .mint
        case 70..<80: .blue
        case 60..<70: .orange
        case 40..<60: .orange
        default: .red
        }
    }
}

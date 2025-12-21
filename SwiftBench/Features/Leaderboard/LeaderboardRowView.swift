//
//  LeaderboardRowView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct LeaderboardRowView: View {
    let run: BenchmarkRun

    @ScaledMetric private var spacing = 6

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack {
                Text(run.modelIdentifier)
                    .font(.headline)

                Spacer()

                Text(run.score, format: .number.precision(.fractionLength(1)))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(run.createdAt, format: .dateTime.year().month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Tokens: \(run.tokenTotal)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

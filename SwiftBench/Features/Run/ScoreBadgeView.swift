//
//  ScoreBadgeView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct ScoreBadgeView: View {
    let score: Double

    @ScaledMetric private var cornerRadius = 16
    @ScaledMetric private var paddingSize = 12

    var body: some View {
        let color = scoreColor(for: score)
        Text(score, format: .number.precision(.fractionLength(1)))
            .font(.title2.bold())
            .foregroundStyle(color)
            .padding(paddingSize)
            .background(color.opacity(0.15))
            .clipShape(.rect(cornerRadius: cornerRadius))
            .accessibilityLabel("Score")
            .accessibilityValue(Text(score, format: .number.precision(.fractionLength(1))))
    }

    private func scoreColor(for score: Double) -> Color {
        switch score {
        case ..<60:
            return .red
        case ..<80:
            return .orange
        default:
            return .green
        }
    }
}

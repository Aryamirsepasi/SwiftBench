//
//  ScoreBadgeView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

struct ScoreBadgeView: View {
    let score: Double
    var showDetails: Binding<Bool> = .constant(false)

    @State private var animatedScore: Double = 0
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(scoreColor.opacity(0.2), lineWidth: LayoutConstants.progressStrokeWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: LayoutConstants.progressStrokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: LayoutConstants.scoreAnimationDuration), value: animatedScore)

            // Score text
            VStack(spacing: 2) {
                Text(score, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)

                Text(scoreDescriptor)
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size, height: size)
        .background(.ultraThinMaterial, in: Circle())
        .shadow(color: scoreColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                showDetails.wrappedValue.toggle()
            }
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Score: \(Int(score)) out of 100, \(scoreDescriptor)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap for details")
        .onAppear {
            withAnimation(.easeOut(duration: LayoutConstants.scoreAnimationDuration)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { oldValue, newValue in
            withAnimation(.easeOut(duration: LayoutConstants.scoreAnimationDuration)) {
                animatedScore = newValue
            }
        }
    }

    private var size: CGFloat {
        100
    }

    private var scoreColor: Color {
        switch score {
        case ..<60:
            return .red
        case ..<80:
            return .orange
        default:
            return .green
        }
    }

    private var scoreDescriptor: String {
        switch score {
        case 90...: "Excellent"
        case 80..<90: "Great"
        case 70..<80: "Good"
        case 60..<70: "Fair"
        case ..<60: "Needs Work"
        default: ""
        }
    }
}

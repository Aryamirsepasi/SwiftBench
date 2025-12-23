//
//  TaskComponents.swift
//  SwiftBench
//
//  Created by Claude on 23.12.25.
//

import SwiftUI

// MARK: - Test Type Badge

struct TestTypeBadge: View {
    enum TestType {
        case xctest
        case io

        var title: String {
            switch self {
            case .xctest: "XT"
            case .io: "IO"
            }
        }

        var systemImage: String {
            switch self {
            case .xctest: "checkmark.circle"
            case .io: "arrow.left.arrow.right"
            }
        }

        var badgeColor: Color {
            switch self {
            case .xctest: .blue
            case .io: .green
            }
        }
    }

    let testType: TestType

    var body: some View {
        Label(testType.title, systemImage: testType.systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(testType.badgeColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(testType.badgeColor.opacity(0.1), in: .capsule)
    }
}


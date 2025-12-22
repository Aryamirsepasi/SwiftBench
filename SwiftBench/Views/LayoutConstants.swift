//
//  LayoutConstants.swift
//  SwiftBench
//
//  Created to ensure consistent spacing and layout across all views
//

import SwiftUI

/// Shared layout constants for consistent spacing throughout the app
enum LayoutConstants {
    // MARK: - Section Spacing
    
    /// Vertical spacing between major sections
    static let sectionSpacing: CGFloat = 16
    
    /// Horizontal spacing between controls
    static let controlSpacing: CGFloat = 12
    
    /// Padding for content containers
    static let contentPadding: CGFloat = 16
    
    /// Small padding for compact elements
    static let smallPadding: CGFloat = 8
    
    // MARK: - Corner Radii
    
    /// Standard corner radius for cards and containers
    static let cornerRadius: CGFloat = 16
    
    /// Small corner radius for badges and chips
    static let smallCornerRadius: CGFloat = 8
    
    // MARK: - Dimensions
    
    /// Minimum width for compact sidebar
    static let compactSidebarWidth: CGFloat = 280
    
    /// Ideal width for sidebar
    static let idealSidebarWidth: CGFloat = 320
    
    /// Maximum width for sidebar
    static let maxSidebarWidth: CGFloat = 400
    
    /// Minimum height for text editors
    static let minimumEditorHeight: CGFloat = 200
    
    /// Height for category filter chips
    static let chipHeight: CGFloat = 32
    
    // MARK: - Progress
    
    /// Stroke width for progress rings and gauges
    static let progressStrokeWidth: CGFloat = 8
    
    /// Animation duration for score updates
    static let scoreAnimationDuration: Double = 0.5
    
    // MARK: - Accessibility
    
    /// Minimum touch target size for buttons (44pt per HIG)
    static let minimumTouchTarget: CGFloat = 44
}

/// Scaled metric wrapper for consistent spacing that adapts to Dynamic Type
///
/// IMPORTANT: @ScaledMetric requires a View context to access the environment.
/// Do not use this as a static struct - it must be used within Views.
/// Use `LayoutConstants` directly for static values instead.
@MainActor
struct ScaledMetrics: View {
    @ScaledMetric(relativeTo: .body) var sectionSpacing: CGFloat = LayoutConstants.sectionSpacing
    @ScaledMetric(relativeTo: .body) var controlSpacing: CGFloat = LayoutConstants.controlSpacing
    @ScaledMetric(relativeTo: .body) var contentPadding: CGFloat = LayoutConstants.contentPadding
    @ScaledMetric(relativeTo: .body) var smallPadding: CGFloat = LayoutConstants.smallPadding
    @ScaledMetric(relativeTo: .body) var cornerRadius: CGFloat = LayoutConstants.cornerRadius
    @ScaledMetric(relativeTo: .body) var smallCornerRadius: CGFloat = LayoutConstants.smallCornerRadius
    @ScaledMetric(relativeTo: .body) var chipHeight: CGFloat = LayoutConstants.chipHeight

    var body: some View {
        EmptyView()
    }
}


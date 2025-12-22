//
//  ShareComponents.swift
//  SwiftBench
//
//  Shared share functionality for all views
//

import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Share sheet data model
struct ShareSheet: Identifiable {
    let id = UUID()
    let items: [Any]
}

#if os(iOS) || os(visionOS)
/// iOS/visionOS share view
struct ShareView: UIViewControllerRepresentable {
    let sheet: ShareSheet

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: sheet.items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
/// macOS share view
struct ShareView: View {
    let sheet: ShareSheet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding()
            }
            
            SharePickerView(items: sheet.items)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 300, height: 200)
    }
}

/// Helper view to present NSSharingServicePicker
private struct SharePickerView: NSViewRepresentable {
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            if view.window != nil {
                let picker = NSSharingServicePicker(items: items)
                picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif


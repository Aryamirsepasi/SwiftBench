//
//  CodeTextView.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import SwiftUI

#if os(macOS)
import AppKit

struct CodeTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.isEditable = false
        view.drawsBackground = false
        let inset = NSFont.systemFontSize * 0.6
        view.textContainerInset = NSSize(width: inset, height: inset)
        view.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return view
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.string = text
    }
}
#else
import UIKit

struct CodeTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear

        let baseFont = UIFont.monospacedSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        view.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
        view.adjustsFontForContentSizeCategory = true

        let inset = UIFontMetrics(forTextStyle: .body).scaledValue(for: 8)
        view.textContainerInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
#endif

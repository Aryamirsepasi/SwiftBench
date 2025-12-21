//
//  PasteboardService.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum PasteboardService {
    static func copy(_ string: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}

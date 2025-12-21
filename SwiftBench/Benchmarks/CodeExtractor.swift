//
//  CodeExtractor.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

struct CodeExtractor {
    static func extract(from text: String) -> String {
        let parts = text.split(separator: "```", omittingEmptySubsequences: false)
        guard parts.count >= 3 else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var largestBlock = ""
        var index = 1
        while index < parts.count {
            var block = String(parts[index])
            if let newlineIndex = block.firstIndex(of: "\n") {
                let firstLine = block[..<newlineIndex]
                if firstLine.count < 12 && !firstLine.contains(" ") {
                    block = String(block[block.index(after: newlineIndex)...])
                }
            }

            if block.count > largestBlock.count {
                largestBlock = block
            }
            index += 2
        }

        return largestBlock.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

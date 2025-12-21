//
//  OpenRouterModelPreset.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

enum OpenRouterModelPreset: String, CaseIterable, Identifiable {
    case devstral2512 = "Devstral 2512"
    case qwen3Coder = "Qwen 3 Coder"
    case claudeSonnet = "Claude 4.5 Sonnet"
    case geminiFlash = "Gemini 3.0 Flash"
    case custom = "Custom"

    var id: String { rawValue }

    var modelID: String? {
        switch self {
        case .devstral2512:
            return "mistralai/devstral-2512"
        case .qwen3Coder:
            return "qwen/qwen3-coder"
        case .claudeSonnet:
            return "anthropic/claude-sonnet-4.5"
        case .geminiFlash:
            return "google/gemini-3-flash-preview"
        case .custom:
            return nil
        }
    }
}

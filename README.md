# SwiftBench

A cross-platform SwiftUI application for benchmarking LLM code generation capabilities using the OpenRouter API. SwiftBench evaluates how well language models can generate modern Swift and SwiftUI code that follows Apple's latest APIs and Human Interface Guidelines.

## Features

- **LLM Benchmarking**: Test any model available through OpenRouter against a comprehensive Swift/SwiftUI benchmark
- **Real-time Streaming**: Watch code generation in real-time with streaming API responses
- **Multi-dimensional Scoring**: Evaluates generated code across 5 dimensions:
  - Token overlap (35%) - Jaccard similarity of code tokens
  - Line overlap (20%) - Structural similarity of code lines
  - Modern APIs (20%) - Usage of latest iOS 26 APIs and patterns
  - Code quality (15%) - Documentation, comments, and best practices
  - Length match (10%) - Similarity in code length
- **Anti-pattern Detection**: Penalizes deprecated APIs and bad practices
- **Leaderboard**: Track and compare model performance over time with SwiftData persistence
- **BYOK**: Bring your own OpenRouter API key (securely stored in Keychain)

## Requirements

- **Xcode 26+** with Swift 6.2
- **iOS 26.0+** / **iPadOS 26.0+** / **macOS 26.0+** / **visionOS 26.0+**
- **OpenRouter API Key**: Get one at [openrouter.ai](https://openrouter.ai)

## Installation

1. Clone the repository
2. Open `SwiftBench.xcodeproj` in Xcode
3. Build and run on your target platform

```bash
# Build for macOS
xcodebuild -project SwiftBench.xcodeproj -scheme SwiftBench -destination 'platform=macOS' build

# Build for iOS Simulator
xcodebuild -project SwiftBench.xcodeproj -scheme SwiftBench -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Usage

1. **Enter API Key**: Add your OpenRouter API key in the "Connection" section and save it
2. **Select Model**: Choose from preset models or enter a custom model identifier
3. **Run Benchmark**: Click "Run Benchmark" to start the evaluation
4. **View Results**: See real-time streaming output and final score breakdown
5. **Track Progress**: Check the Leaderboard tab to compare model performance

## Benchmark Specification

The benchmark evaluates LLM ability to generate a complete SwiftUI application with:

### Required Modern APIs
- `@MainActor @Observable` state management
- SwiftData `@Model` for persistence
- `NavigationStack` with modern `Tab` API
- `NSViewRepresentable` / `UIViewRepresentable` for platform integration
- `async/await` concurrency
- `foregroundStyle()` and `clipShape(.rect(cornerRadius:))`
- `ContentUnavailableView` for empty states
- `@ScaledMetric` for Dynamic Type support
- `scrollIndicators(.hidden)` modifier

### Code Quality Expectations
- Documentation comments (`///` and `// MARK:`)
- Proper access control (`private var/func/let`)
- Accessibility labels and values
- Following Apple Human Interface Guidelines

### Anti-patterns (Penalized)
- `DispatchQueue` (use async/await instead)
- `ObservableObject` / `@Published` (use @Observable)
- `foregroundColor()` (use foregroundStyle)
- `cornerRadius()` (use clipShape)
- `.tabItem()` (use Tab API)
- `NavigationView` (use NavigationStack)
- Force unwraps (`try!`, `as!`)

## Architecture

```
SwiftBench/
├── App/              - App entry point, global state
├── Benchmarks/       - Benchmark specs and scoring algorithms
├── Features/         - Feature-specific views
│   ├── Run/          - Benchmark execution interface
│   ├── Leaderboard/  - Historical results and rankings
│   └── Benchmark/    - Reference code display
├── Models/           - SwiftData models and domain types
├── Services/         - Keychain and platform services
└── Views/            - Shared UI components
```

### Key Components

- **AppState**: `@MainActor @Observable` class managing global application state
- **BenchmarkScorer**: Multi-dimensional scoring algorithm with anti-pattern detection
- **CodeExtractor**: Extracts code blocks from LLM responses (handles markdown)
- **CodeTextView**: Platform-specific scrollable code display (AppKit/UIKit)

## Model Presets

| Model | Identifier |
|-------|------------|
| Devstral 2512 | `mistralai/devstral-2512` |
| Qwen 3 Coder | `qwen/qwen3-coder` |
| Claude 4.5 Sonnet | `anthropic/claude-sonnet-4.5` |
| Gemini 3.0 Flash | `google/gemini-3-flash-preview` |

You can also enter any custom model identifier supported by OpenRouter.

## Technical Details

- **Swift 6.2** with strict concurrency enabled
- **SwiftData** for persistent storage
- **Keychain** for secure API key storage
- **AIProxy** library for OpenRouter streaming API
- **Sandboxed** with network access enabled

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure your code follows the project's coding standards:

- Use modern Swift APIs (iOS 26+)
- Follow Apple Human Interface Guidelines
- Add documentation comments for public APIs
- Include accessibility labels for UI elements

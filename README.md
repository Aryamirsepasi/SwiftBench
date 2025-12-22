# SwiftBench

A cross-platform SwiftUI application for benchmarking LLM code generation capabilities using the OpenRouter API. SwiftBench evaluates how well language models can generate modern Swift and SwiftUI code that follows Apple's latest APIs and Human Interface Guidelines.

## Features

### Single Benchmark Mode
- **LLM Benchmarking**: Test any model available through OpenRouter against a comprehensive Swift/SwiftUI benchmark
- **Real-time Streaming**: Watch code generation in real-time with streaming API responses
- **Multi-dimensional Scoring**: Evaluates generated code across 5 dimensions:
  - Token overlap (35%) - Jaccard similarity of code tokens
  - Line overlap (20%) - Structural similarity of code lines
  - Modern APIs (20%) - Usage of latest iOS 26 APIs and patterns
  - Code quality (15%) - Documentation, comments, and best practices
  - Length match (10%) - Similarity in code length
- **Anti-pattern Detection**: Penalizes deprecated APIs and bad practices

### Comprehensive Test Suite (SwiftBench Suite v2)
- **24 Benchmark Tasks** across 6 categories:
  - **Algorithms** - Classic implementations (Fibonacci, Palindrome, Binary Search, Two Sum)
  - **Data Modeling** - SwiftData models and relationships
  - **Concurrency** - async/await, Actors, Sendable protocols
  - **SwiftUI Composition** - View composition, state management, navigation
  - **SwiftData Queries** - Predicates, sorting, filtering, and query optimization
  - **Refactors & Bug Fixes** - Modernizing deprecated patterns and fixing bugs
- **Pass@k Evaluation**: Run each task multiple times (configurable) to measure reliability
- **Execution-Based Scoring** (macOS only):
  - Automatic compilation of generated Swift code
  - XCTest execution against test suites
  - AST-based style analysis for modern Swift patterns
  - Score breakdown: Compilation (30%) + Test Pass Rate (70%)
- **Style Analysis**: Detects modern Swift patterns using SwiftSyntax AST parsing
- **Aggregate Metrics**:
  - Pass@1 - Tasks where at least one run passed all tests
  - Pass@k - Tasks where all k runs passed all tests
  - Mean Score - Average score across all runs
  - Category Breakdown - Performance by task category
  - Token Usage - Total tokens consumed
  - Execution Time - Total time for compilation and testing

### Results & Management
- **Leaderboard**: Track and compare model performance over time with SwiftData persistence
- **Suite Results**: View aggregate metrics and category breakdowns for suite runs
- **Export to CSV**: Export leaderboard data for external analysis
- **Delete & Reset**: Remove individual runs or reset entire leaderboard
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

### Single Benchmark Mode
1. **Enter API Key**: Add your OpenRouter API key in the "Connection" section and save it
2. **Select Model**: Choose from preset models or enter a custom model identifier
3. **Enter Prompt**: Type your prompt or use the benchmark template
4. **Run Benchmark**: Click "Run Benchmark" to start the evaluation
5. **View Results**: See real-time streaming output and final score breakdown

### Test Suite Mode (macOS)
1. **Select Suite**: Choose SwiftBench Suite v2 with 24 tasks
2. **Configure Runs**: Set runs per task (for Pass@k evaluation) and temperature
3. **Run Suite**: Execute all tasks in the suite
4. **Track Progress**: Monitor real-time progress with task-by-task feedback
5. **Review Results**: Check Suite Results tab for aggregate metrics and category breakdowns

### Leaderboard Management
1. **Filter & Sort**: Use the filter and sort controls to explore results
2. **Delete Runs**: Swipe left on iOS or use context menu to delete individual runs
3. **Reset Leaderboard**: Use the Actions menu to clear all results
4. **Export CSV**: Export filtered results for external analysis
5. **View Details**: Tap any run to see detailed information

## Benchmark Specification

### Single Benchmark (Legacy)
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

### Test Suite (SwiftBench v2)
The test suite evaluates LLM ability to generate correct, modern Swift code across multiple categories:

#### Task Categories
1. **Algorithms** (4 tasks)
   - Classic algorithm implementations
   - Efficient iterative solutions
   - Input/output validation

2. **Data Modeling** (4 tasks)
   - SwiftData `@Model` definitions
   - Relationships (one-to-one, one-to-many)
   - Computed properties and validation

3. **Concurrency** (4 tasks)
   - `async/await` patterns
   - Actor isolation
   - Sendable conformance
   - Structured concurrency

4. **SwiftUI Composition** (4 tasks)
   - View composition and modifiers
   - State management (`@Observable`, `@State`, `@Binding`)
   - Navigation with `NavigationStack` and `Tab` API
   - Lists and ForEach

5. **SwiftData Queries** (4 tasks)
   - `@Query` predicates
   - Sorting and filtering
   - Aggregate calculations
   - Relationship queries

6. **Refactors & Bug Fixes** (4 tasks)
   - Modernizing deprecated APIs
   - Fixing concurrency issues
   - Correcting SwiftUI patterns
   - Memory leak fixes

#### Difficulty Levels
- **Easy** - Simple implementations, straightforward APIs
- **Medium** - Multiple concepts involved, requires careful implementation
- **Hard** - Complex scenarios, edge cases, advanced patterns

#### Execution Scoring (macOS only)
Generated code is compiled and tested automatically:
- **Compilation**: Code must compile without errors
- **Testing**: Code passes all XCTest cases
- **Style Analysis**: AST parsing detects modern Swift patterns
- **Score Formula**: 30% (compilation) + 70% (test pass rate)

#### Pass@k Evaluation
Run each task `k` times to measure consistency:
- **Pass@1**: Task passed if any one run succeeded
- **Pass@k**: Task passed if all `k` runs succeeded
- **Mean Score**: Average score across all runs

## Architecture

```
SwiftBench/
├── App/              - App entry point, global state
├── Benchmarks/       - Benchmark specs and scoring algorithms
│   └── Suites/      - Comprehensive test suite definitions
├── Features/         - Feature-specific views
│   ├── Run/          - Benchmark execution interface
│   ├── Leaderboard/  - Historical results and rankings
│   ├── Suite/        - Suite run configuration and progress
│   ├── Results/      - Suite result aggregation and display
│   └── Tasks/       - Individual task browsing and details
├── Models/           - SwiftData models and domain types
├── Services/         - Keychain, test execution, CSV export
└── Views/            - Shared UI components
```

### Key Components

- **AppState**: `@MainActor @Observable` class managing global application state and suite runs
- **BenchmarkSuite**: Versioned collections of benchmark tasks with metadata
- **BenchmarkTask**: Individual test tasks with prompts, tests, and style rules
- **BenchmarkScorer**: Multi-dimensional scoring algorithm with anti-pattern detection
- **TestExecutionService**: Compiles and executes generated Swift code with XCTest (macOS)
- **ExecutionScorer**: Scores execution results based on compilation and test pass rate
- **CodeExtractor**: Extracts code blocks from LLM responses (handles markdown)
- **LeaderboardExporter**: Generates CSV exports of leaderboard data
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

See LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure your code follows the project's coding standards:

- Use modern Swift APIs (iOS 26+)
- Follow Apple Human Interface Guidelines
- Add documentation comments for public APIs
- Include accessibility labels for UI elements

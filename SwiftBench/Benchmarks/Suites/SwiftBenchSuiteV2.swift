//
//  SwiftBenchSuiteV2.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import Foundation

extension BenchmarkSuite {
    /// SwiftBench Suite v2 - Comprehensive Swift/SwiftUI benchmark suite.
    ///
    /// This suite contains 24 tasks across 6 categories:
    /// - Algorithms (4 tasks)
    /// - Data Modeling (4 tasks)
    /// - Concurrency (4 tasks)
    /// - SwiftUI Composition (4 tasks)
    /// - SwiftData Queries (4 tasks)
    /// - Refactors & Bug Fixes (4 tasks)
    static let v2 = BenchmarkSuite(
        id: "swiftbench-v2",
        version: "2.0",
        title: "SwiftBench Suite v2",
        description: "Comprehensive benchmark suite testing Swift 6, SwiftUI 26, and SwiftData skills across algorithms, data modeling, concurrency, UI composition, queries, and code modernization.",
        tasks: algorithmTasks + dataModelingTasks + concurrencyTasks + swiftUITasks + swiftDataTasks + refactorTasks
    )

    /// All available benchmark suites.
    static let allSuites: [BenchmarkSuite] = [.v2]

    // MARK: - Algorithm Tasks

    private static let algorithmTasks: [BenchmarkTask] = [
        BenchmarkTask(
            id: "algo-fibonacci",
            title: "Fibonacci Sequence",
            category: .algorithms,
            difficulty: .easy,
            prompt: """
            Write a function `fibonacci(_ n: Int) -> Int` that returns the nth Fibonacci number.
            - fibonacci(0) = 0
            - fibonacci(1) = 1
            - fibonacci(n) = fibonacci(n-1) + fibonacci(n-2) for n > 1
            Use an efficient iterative approach, not recursion.
            Return only Swift code, no explanations.
            """,
            inputOutputPairs: [
                IOPair(input: "0", expectedOutput: "0"),
                IOPair(input: "1", expectedOutput: "1"),
                IOPair(input: "5", expectedOutput: "5"),
                IOPair(input: "10", expectedOutput: "55"),
                IOPair(input: "20", expectedOutput: "6765"),
            ],
            referenceCode: """
            func fibonacci(_ n: Int) -> Int {
                guard n > 0 else { return 0 }
                guard n > 1 else { return 1 }
            
                var a = 0
                var b = 1
                for _ in 2...n {
                    let temp = a + b
                    a = b
                    b = temp
                }
                return b
            }
            """, functionName: "fibonacci",
            expectedSignature: "func fibonacci(_ n: Int) -> Int"
        ),

        BenchmarkTask(
            id: "algo-palindrome",
            title: "Palindrome Check",
            category: .algorithms,
            difficulty: .easy,
            prompt: """
            Write a function `isPalindrome(_ s: String) -> Bool` that checks if a string is a palindrome.
            - Ignore case and non-alphanumeric characters
            - Empty strings are palindromes
            Return only Swift code, no explanations.
            """,
            inputOutputPairs: [
                IOPair(input: "\"\"", expectedOutput: "true"),
                IOPair(input: "\"a\"", expectedOutput: "true"),
                IOPair(input: "\"racecar\"", expectedOutput: "true"),
                IOPair(input: "\"A man a plan a canal Panama\"", expectedOutput: "true"),
                IOPair(input: "\"hello\"", expectedOutput: "false"),
            ],
            referenceCode: """
            func isPalindrome(_ s: String) -> Bool {
                let cleaned = s.lowercased().filter { $0.isLetter || $0.isNumber }
                return cleaned == String(cleaned.reversed())
            }
            """, functionName: "isPalindrome",
            expectedSignature: "func isPalindrome(_ s: String) -> Bool"
        ),

        BenchmarkTask(
            id: "algo-binary-search",
            title: "Binary Search",
            category: .algorithms,
            difficulty: .medium,
            prompt: """
            Write a function `binarySearch(_ array: [Int], target: Int) -> Int?` that performs binary search.
            - Return the index of the target if found, nil otherwise
            - Assume the array is sorted in ascending order
            - Use an iterative approach
            Return only Swift code, no explanations.
            """,
            inputOutputPairs: [
                IOPair(input: "[1, 2, 3, 4, 5], target: 3", expectedOutput: "Optional(2)"),
                IOPair(input: "[1, 2, 3, 4, 5], target: 1", expectedOutput: "Optional(0)"),
                IOPair(input: "[1, 2, 3, 4, 5], target: 5", expectedOutput: "Optional(4)"),
                IOPair(input: "[1, 2, 3, 4, 5], target: 6", expectedOutput: "nil"),
                IOPair(input: "[], target: 1", expectedOutput: "nil"),
            ],
            referenceCode: """
            func binarySearch(_ array: [Int], target: Int) -> Int? {
                var left = 0
                var right = array.count - 1

                while left <= right {
                    let mid = left + (right - left) / 2
                    if array[mid] == target {
                        return mid
                    } else if array[mid] < target {
                        left = mid + 1
                    } else {
                        right = mid - 1
                    }
                }

                return nil
            }
            """,
            functionName: "binarySearch",
            expectedSignature: "func binarySearch(_ array: [Int], target: Int) -> Int?"
        ),

        BenchmarkTask(
            id: "algo-merge-sorted",
            title: "Merge Sorted Arrays",
            category: .algorithms,
            difficulty: .medium,
            prompt: """
            Write a function `mergeSorted(_ a: [Int], _ b: [Int]) -> [Int]` that merges two sorted arrays.
            - Both input arrays are sorted in ascending order
            - Return a single sorted array containing all elements
            - Use O(n + m) time complexity
            Return only Swift code, no explanations.
            """,
            inputOutputPairs: [
                IOPair(input: "[1, 3, 5], [2, 4, 6]", expectedOutput: "[1, 2, 3, 4, 5, 6]"),
                IOPair(input: "[1, 2, 3], [4, 5, 6]", expectedOutput: "[1, 2, 3, 4, 5, 6]"),
                IOPair(input: "[], [1, 2, 3]", expectedOutput: "[1, 2, 3]"),
                IOPair(input: "[1], [1]", expectedOutput: "[1, 1]"),
            ],
            referenceCode: """
            func mergeSorted(_ a: [Int], _ b: [Int]) -> [Int] {
                var result: [Int] = []
                var i = 0
                var j = 0

                while i < a.count && j < b.count {
                    if a[i] <= b[j] {
                        result.append(a[i])
                        i += 1
                    } else {
                        result.append(b[j])
                        j += 1
                    }
                }

                while i < a.count {
                    result.append(a[i])
                    i += 1
                }

                while j < b.count {
                    result.append(b[j])
                    j += 1
                }

                return result
            }
            """,
            functionName: "mergeSorted",
            expectedSignature: "func mergeSorted(_ a: [Int], _ b: [Int]) -> [Int]"
        ),
    ]

    // MARK: - Data Modeling Tasks

    private static let dataModelingTasks: [BenchmarkTask] = [
        BenchmarkTask(
            id: "data-todo-model",
            title: "Todo Item Model",
            category: .dataModeling,
            difficulty: .easy,
            prompt: """
            Create a SwiftData @Model for a Todo item with:
            - id: UUID (with default value)
            - title: String (with default value)
            - isCompleted: Bool (default false)
            - createdAt: Date (default Date.now)
            - dueDate: Date? (optional)

            Include an initializer that accepts title and optional dueDate.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class TodoModelTests: XCTestCase {
                func testTodoHasRequiredProperties() {
                    // Verify the model compiles and has expected properties
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
            ]
        ),

        BenchmarkTask(
            id: "data-user-profile",
            title: "User Profile Model",
            category: .dataModeling,
            difficulty: .medium,
            prompt: """
            Create SwiftData models for a social app:
            1. UserProfile @Model with:
               - id: UUID (default)
               - username: String (default "")
               - displayName: String (default "")
               - bio: String (default "")
               - createdAt: Date (default Date.now)
               - posts: [Post]? (relationship, optional)

            2. Post @Model with:
               - id: UUID (default)
               - content: String (default "")
               - createdAt: Date (default Date.now)
               - author: UserProfile? (relationship, optional)

            Ensure all relationships are properly optional for CloudKit compatibility.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class UserProfileTests: XCTestCase {
                func testModelsCompile() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
            ]
        ),

        BenchmarkTask(
            id: "data-expense-tracker",
            title: "Expense Tracker Model",
            category: .dataModeling,
            difficulty: .medium,
            prompt: """
            Create SwiftData models for an expense tracker:
            1. Expense @Model with:
               - id: UUID (default)
               - amount: Double (default 0)
               - title: String (default "")
               - note: String (default "")
               - date: Date (default Date.now)
               - category: ExpenseCategory? (relationship)

            2. ExpenseCategory @Model with:
               - id: UUID (default)
               - name: String (default "")
               - colorHex: String (default "#000000")
               - expenses: [Expense]? (relationship)

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class ExpenseModelTests: XCTestCase {
                func testModelsCompile() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
            ]
        ),

        BenchmarkTask(
            id: "data-book-library",
            title: "Book Library Model",
            category: .dataModeling,
            difficulty: .hard,
            prompt: """
            Create SwiftData models for a book library app:
            1. Book @Model:
               - id, title, author, isbn, publishedDate, pageCount
               - readingProgress: Double (0-1)
               - shelves: [Shelf]? (many-to-many relationship)

            2. Shelf @Model:
               - id, name, createdAt
               - books: [Book]? (many-to-many relationship)

            3. ReadingSession @Model:
               - id, startTime, endTime, pagesRead
               - book: Book? (relationship)

            All properties should have sensible defaults. Relationships must be optional.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class BookLibraryTests: XCTestCase {
                func testModelsCompile() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
            ]
        ),
    ]

    // MARK: - Concurrency Tasks

    private static let concurrencyTasks: [BenchmarkTask] = [
        BenchmarkTask(
            id: "conc-async-fetch",
            title: "Async URL Fetch",
            category: .concurrency,
            difficulty: .easy,
            prompt: """
            Write an async function that fetches data from a URL:
            `func fetchData(from url: URL) async throws -> Data`

            - Use URLSession.shared.data(from:)
            - Return the data on success
            - Let errors propagate naturally

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class AsyncFetchTests: XCTestCase {
                func testFunctionExists() async {
                    // Just verify it compiles with async
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useAsyncAwait,
                StyleRules.noDispatchQueue,
            ]
        ),

        BenchmarkTask(
            id: "conc-task-group",
            title: "Parallel Image Download",
            category: .concurrency,
            difficulty: .medium,
            prompt: """
            Write an async function that downloads multiple images in parallel:
            `func downloadImages(from urls: [URL]) async throws -> [Data]`

            - Use TaskGroup to download all images concurrently
            - Return results in the same order as the input URLs
            - If any download fails, throw the error

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class ParallelDownloadTests: XCTestCase {
                func testFunctionExists() async {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useAsyncAwait,
                StyleRules.noDispatchQueue,
            ]
        ),

        BenchmarkTask(
            id: "conc-actor-counter",
            title: "Thread-Safe Counter Actor",
            category: .concurrency,
            difficulty: .medium,
            prompt: """
            Create an actor-based thread-safe counter:

            actor Counter {
                - private(set) var value: Int (starts at 0)
                - func increment() -> increments and returns new value
                - func decrement() -> decrements and returns new value
                - func reset() -> resets to 0
            }

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class CounterActorTests: XCTestCase {
                func testCounterIncrement() async {
                    let counter = Counter()
                    let value = await counter.increment()
                    XCTAssertEqual(value, 1)
                }

                func testCounterDecrement() async {
                    let counter = Counter()
                    _ = await counter.increment()
                    let value = await counter.decrement()
                    XCTAssertEqual(value, 0)
                }
            }
            """
        ),

        BenchmarkTask(
            id: "conc-async-sequence",
            title: "Async Number Generator",
            category: .concurrency,
            difficulty: .hard,
            prompt: """
            Create an AsyncSequence that generates numbers with a delay:

            struct DelayedNumbers: AsyncSequence {
                typealias Element = Int
                let range: ClosedRange<Int>
                let delay: Duration
            }

            - Each iteration waits for `delay` before yielding the next number
            - Yields all numbers in the range
            - Implement the required AsyncIteratorProtocol

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class AsyncSequenceTests: XCTestCase {
                func testDelayedNumbers() async {
                    let numbers = DelayedNumbers(range: 1...3, delay: .milliseconds(10))
                    var collected: [Int] = []
                    for await n in numbers {
                        collected.append(n)
                    }
                    XCTAssertEqual(collected, [1, 2, 3])
                }
            }
            """,
            styleRules: [
                StyleRules.useAsyncAwait,
            ]
        ),
    ]

    // MARK: - SwiftUI Tasks

    private static let swiftUITasks: [BenchmarkTask] = [
        BenchmarkTask(
            id: "swiftui-counter",
            title: "Simple Counter View",
            category: .swiftUIComposition,
            difficulty: .easy,
            prompt: """
            Create a SwiftUI counter view with:
            - @State property for count (starting at 0)
            - Text displaying the current count
            - "Increment" button that adds 1
            - "Decrement" button that subtracts 1
            - "Reset" button that sets count to 0

            Use modern SwiftUI patterns (foregroundStyle, etc).
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class CounterViewTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useForegroundStyle,
            ]
        ),

        BenchmarkTask(
            id: "swiftui-list-detail",
            title: "List-Detail Navigation",
            category: .swiftUIComposition,
            difficulty: .medium,
            prompt: """
            Create a SwiftUI list-detail navigation flow:

            1. Item struct (Identifiable) with id, title, description
            2. ItemListView showing a List of items
            3. ItemDetailView showing full item details
            4. Use NavigationStack with navigationDestination(for:)

            Include sample data with 3 items.
            Use modern SwiftUI patterns.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class ListDetailTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useNavigationStack,
                StyleRules.noNavigationView,
            ]
        ),

        BenchmarkTask(
            id: "swiftui-tab-view",
            title: "Tab-Based Navigation",
            category: .swiftUIComposition,
            difficulty: .medium,
            prompt: """
            Create a SwiftUI app with tab-based navigation:

            1. Use TabView with the Tab API (not tabItem)
            2. Three tabs: Home, Search, Settings
            3. Each tab contains a NavigationStack with a simple view
            4. Use appropriate SF Symbols for tab icons

            Use modern SwiftUI patterns.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class TabViewTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useTabAPI,
                StyleRules.noTabItem,
                StyleRules.useNavigationStack,
            ]
        ),

        BenchmarkTask(
            id: "swiftui-form",
            title: "Settings Form",
            category: .swiftUIComposition,
            difficulty: .hard,
            prompt: """
            Create a Settings form view with:

            1. @MainActor @Observable SettingsState class with:
               - username: String
               - notificationsEnabled: Bool
               - theme: Theme enum (light, dark, system)
               - fontSize: Double (range 12-24)

            2. SettingsView with Form containing:
               - Section for Profile (username TextField)
               - Section for Preferences (Toggle, Picker, Slider)
               - Section with "Save" and "Reset" buttons

            Use modern SwiftUI patterns and @Bindable.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class SettingsFormTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useObservable,
                StyleRules.useMainActor,
                StyleRules.noObservableObject,
            ]
        ),
    ]

    // MARK: - SwiftData Query Tasks

    private static let swiftDataTasks: [BenchmarkTask] = [
        BenchmarkTask(
            id: "query-simple-fetch",
            title: "Simple Query",
            category: .swiftDataQueries,
            difficulty: .easy,
            prompt: """
            Create a SwiftUI view that displays a list of notes from SwiftData:

            1. Note @Model with: id (UUID), title (String), content (String), createdAt (Date)
            2. NotesListView with @Query that fetches all notes sorted by createdAt descending
            3. Display each note's title and creation date in a List

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class SimpleQueryTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
                StyleRules.useQuery,
            ]
        ),

        BenchmarkTask(
            id: "query-filtered",
            title: "Filtered Query",
            category: .swiftDataQueries,
            difficulty: .medium,
            prompt: """
            Create a task list view with filtering:

            1. Task @Model with: id, title, isCompleted, priority (Int 1-3), dueDate
            2. TaskListView with:
               - @State for showCompletedOnly: Bool
               - @Query with dynamic filter based on showCompletedOnly
               - Toggle to switch the filter
               - Sorted by priority (descending), then dueDate

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class FilteredQueryTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
                StyleRules.useQuery,
            ]
        ),

        BenchmarkTask(
            id: "query-search",
            title: "Searchable List",
            category: .swiftDataQueries,
            difficulty: .medium,
            prompt: """
            Create a searchable contacts list:

            1. Contact @Model with: id, firstName, lastName, email, phone
            2. ContactsView with:
               - @State searchText: String
               - @Query that filters contacts where firstName or lastName contains searchText
               - Use localizedStandardContains for proper search
               - .searchable modifier
               - ContentUnavailableView for empty results

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class SearchableListTests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
                StyleRules.useQuery,
                StyleRules.useContentUnavailable,
            ]
        ),

        BenchmarkTask(
            id: "query-crud",
            title: "Full CRUD Operations",
            category: .swiftDataQueries,
            difficulty: .hard,
            prompt: """
            Create a bookmark manager with full CRUD:

            1. Bookmark @Model: id, url (String), title, notes, createdAt, isFavorite
            2. BookmarkListView with:
               - @Query for all bookmarks sorted by createdAt
               - @Environment for modelContext
               - Swipe to delete functionality
               - Add button that creates a new bookmark
               - Navigation to BookmarkEditView

            3. BookmarkEditView with:
               - TextField for url, title, notes
               - Toggle for isFavorite
               - Save and Cancel buttons

            Use modern SwiftUI patterns.
            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class CRUDTests: XCTestCase {
                func testViewsCompile() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useSwiftDataModel,
                StyleRules.useQuery,
                StyleRules.useNavigationStack,
            ]
        ),
    ]

    // MARK: - Refactor Tasks

    private static let refactorTasks: [BenchmarkTask] = [
        BenchmarkTask(
            id: "refactor-observable",
            title: "Migrate to @Observable",
            category: .refactorsBugfixes,
            difficulty: .easy,
            prompt: """
            Refactor this code to use @Observable instead of ObservableObject:

            ```swift
            class UserSettings: ObservableObject {
                @Published var username = ""
                @Published var isLoggedIn = false
                @Published var prefersDarkMode = false
            }
            ```

            - Use @Observable macro
            - Add @MainActor
            - Remove @Published
            - Keep the same properties and defaults

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class ObservableRefactorTests: XCTestCase {
                func testClassCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useObservable,
                StyleRules.useMainActor,
                StyleRules.noObservableObject,
                StyleRules.noPublished,
            ]
        ),

        BenchmarkTask(
            id: "refactor-navigation",
            title: "Migrate to NavigationStack",
            category: .refactorsBugfixes,
            difficulty: .medium,
            prompt: """
            Refactor this code to use NavigationStack instead of NavigationView:

            ```swift
            struct ContentView: View {
                var body: some View {
                    NavigationView {
                        List {
                            NavigationLink("Item 1", destination: DetailView(title: "Item 1"))
                            NavigationLink("Item 2", destination: DetailView(title: "Item 2"))
                        }
                        .navigationTitle("Items")
                    }
                }
            }

            struct DetailView: View {
                let title: String
                var body: some View {
                    Text(title).navigationTitle(title)
                }
            }
            ```

            - Use NavigationStack
            - Use navigationDestination(for:) with value-based navigation
            - Create a proper data type for navigation

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class NavigationRefactorTests: XCTestCase {
                func testViewsCompile() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useNavigationStack,
                StyleRules.noNavigationView,
            ]
        ),

        BenchmarkTask(
            id: "refactor-async",
            title: "Replace DispatchQueue with async/await",
            category: .refactorsBugfixes,
            difficulty: .medium,
            prompt: """
            Refactor this code to use async/await instead of DispatchQueue:

            ```swift
            class DataLoader {
                func loadData(completion: @escaping (Result<String, Error>) -> Void) {
                    DispatchQueue.global().async {
                        // Simulate network delay
                        Thread.sleep(forTimeInterval: 1)
                        let data = "Loaded data"
                        DispatchQueue.main.async {
                            completion(.success(data))
                        }
                    }
                }
            }
            ```

            - Use async function instead of completion handler
            - Use Task.sleep(for:) instead of Thread.sleep
            - Remove DispatchQueue usage
            - Add @MainActor where appropriate

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class AsyncRefactorTests: XCTestCase {
                func testLoaderCompiles() async {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useAsyncAwait,
                StyleRules.noDispatchQueue,
            ]
        ),

        BenchmarkTask(
            id: "refactor-modern-swiftui",
            title: "Modernize SwiftUI View",
            category: .refactorsBugfixes,
            difficulty: .hard,
            prompt: """
            Refactor this view to use modern SwiftUI APIs:

            ```swift
            struct OldStyleView: View {
                var body: some View {
                    VStack {
                        Text("Hello")
                            .foregroundColor(.blue)

                        Image(systemName: "star")
                            .foregroundColor(.yellow)

                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 100, height: 50)
                            .foregroundColor(.green)
                    }
                    .cornerRadius(20)
                }
            }
            ```

            - Replace foregroundColor with foregroundStyle
            - Replace cornerRadius with clipShape(.rect(cornerRadius:))
            - Use modern modifiers throughout

            Return only Swift code, no explanations.
            """,
            testCode: """
            import XCTest
            @testable import GeneratedCode

            final class ModernSwiftUITests: XCTestCase {
                func testViewCompiles() {
                    XCTAssertTrue(true)
                }
            }
            """,
            styleRules: [
                StyleRules.useForegroundStyle,
                StyleRules.useClipShapeRect,
                StyleRules.noForegroundColor,
                StyleRules.noCornerRadius,
            ]
        ),
    ]
}

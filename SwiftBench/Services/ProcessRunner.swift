//
//  ProcessRunner.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

#if os(macOS)

import Foundation

/// Errors that can occur during process execution.
enum ProcessRunnerError: Error, LocalizedError {
    case swiftNotFound
    case processCreationFailed
    case timeout
    case executionFailed(exitCode: Int32, stderr: String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .swiftNotFound:
            "Swift toolchain not found at /usr/bin/swift"
        case .processCreationFailed:
            "Failed to create process"
        case .timeout:
            "Process execution timed out"
        case let .executionFailed(exitCode, stderr):
            "Process failed with exit code \(exitCode): \(stderr)"
        case .cancelled:
            "Process execution was cancelled"
        }
    }
}

/// Result of a process execution.
struct ProcessResult: Sendable {
    /// Exit code from the process.
    let exitCode: Int32

    /// Standard output captured from the process.
    let stdout: String

    /// Standard error captured from the process.
    let stderr: String

    /// Duration of the process execution.
    let duration: TimeInterval

    /// Whether the process succeeded (exit code 0).
    var succeeded: Bool {
        exitCode == 0
    }

    /// Combined stdout and stderr output.
    var combinedOutput: String {
        [stdout, stderr]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

/// Runs shell commands asynchronously using Foundation's Process.
///
/// This is macOS-only and provides async/await wrappers around Process.
enum ProcessRunner {
    /// Path to the Swift executable.
    static let swiftPath = URL(filePath: "/usr/bin/swift")

    /// Checks if Swift is available on the system.
    static var isSwiftAvailable: Bool {
        FileManager.default.isExecutableFile(atPath: swiftPath.path())
    }

    /// Runs a Swift command with the given arguments.
    ///
    /// - Parameters:
    ///   - arguments: Arguments to pass to swift (e.g., ["build"] or ["test"])
    ///   - workingDirectory: The directory to run the command in
    ///   - timeout: Maximum time to wait for completion
    /// - Returns: The result of the process execution
    static func runSwift(
        arguments: [String],
        workingDirectory: URL,
        timeout: TimeInterval = 120
    ) async throws -> ProcessResult {
        guard isSwiftAvailable else {
            throw ProcessRunnerError.swiftNotFound
        }

        return try await run(
            executable: swiftPath,
            arguments: arguments,
            workingDirectory: workingDirectory,
            timeout: timeout
        )
    }

    /// Runs an executable with the given arguments.
    ///
    /// - Parameters:
    ///   - executable: Path to the executable
    ///   - arguments: Arguments to pass to the executable
    ///   - workingDirectory: The directory to run the command in
    ///   - timeout: Maximum time to wait for completion
    /// - Returns: The result of the process execution
    static func run(
        executable: URL,
        arguments: [String],
        workingDirectory: URL,
        timeout: TimeInterval = 120
    ) async throws -> ProcessResult {
        let startTime = Date()

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory

        // Set up pipes for stdout and stderr
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Start the process
        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.processCreationFailed
        }

        // Use a task group to handle timeout and waiting for the process
        return try await withThrowingTaskGroup(of: ProcessResult?.self) { group in
            // Task 1: Wait for process completion
            group.addTask {
                process.waitUntilExit()

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                let duration = Date().timeIntervalSince(startTime)

                return ProcessResult(
                    exitCode: process.terminationStatus,
                    stdout: stdout,
                    stderr: stderr,
                    duration: duration
                )
            }

            // Task 2: Timeout handler
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                if process.isRunning {
                    process.terminate()
                }
                return nil // Signal timeout
            }

            // Wait for first result
            if let result = try await group.next() {
                group.cancelAll()
                if let processResult = result {
                    return processResult
                } else {
                    // Timeout occurred
                    throw ProcessRunnerError.timeout
                }
            }

            throw ProcessRunnerError.processCreationFailed
        }
    }

    /// Runs `swift build` in the given directory.
    static func swiftBuild(
        in directory: URL,
        timeout: TimeInterval = 120
    ) async throws -> ProcessResult {
        try await runSwift(
            arguments: ["build"],
            workingDirectory: directory,
            timeout: timeout
        )
    }

    /// Runs `swift test` in the given directory.
    static func swiftTest(
        in directory: URL,
        timeout: TimeInterval = 180
    ) async throws -> ProcessResult {
        try await runSwift(
            arguments: ["test"],
            workingDirectory: directory,
            timeout: timeout
        )
    }

    /// Runs `swift build` followed by `swift test` in the given directory.
    ///
    /// - Returns: A tuple of (build result, test result). Test result is nil if build failed.
    static func buildAndTest(
        in directory: URL,
        buildTimeout: TimeInterval = 120,
        testTimeout: TimeInterval = 180
    ) async throws -> (build: ProcessResult, test: ProcessResult?) {
        let buildResult = try await swiftBuild(in: directory, timeout: buildTimeout)

        guard buildResult.succeeded else {
            return (buildResult, nil)
        }

        let testResult = try await swiftTest(in: directory, timeout: testTimeout)
        return (buildResult, testResult)
    }
}

#endif

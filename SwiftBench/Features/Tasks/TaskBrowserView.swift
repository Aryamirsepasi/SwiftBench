//
//  TaskBrowserView.swift
//  SwiftBench
//
//  Created by Claude on 22.12.25.
//

import SwiftUI

/// View for browsing all benchmark tasks organized by category.
struct TaskBrowserView: View {
    @State private var selectedSuite: BenchmarkSuite = .v2
    @State private var searchText = ""
    @State private var selectedCategory: BenchmarkCategory?

    private var filteredTasks: [BenchmarkTask] {
        var tasks = selectedSuite.tasks

        // Filter by category if selected
        if let category = selectedCategory {
            tasks = tasks.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.title.localizedStandardContains(searchText)
                    || task.prompt.localizedStandardContains(searchText)
                    || task.category.displayName.localizedStandardContains(searchText)
            }
        }

        return tasks
    }

    var body: some View {
        NavigationStack {
            List {
                categoryFilterSection

                if filteredTasks.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    tasksSection
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .navigationDestination(for: BenchmarkTask.self) { task in
                TaskDetailView(task: task)
            }
        }
    }

    // MARK: - Sections

    private var categoryFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    CategoryFilterChip(
                        title: "All",
                        systemImage: "square.grid.2x2",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(BenchmarkCategory.allCases) { category in
                        CategoryFilterChip(
                            title: category.displayName,
                            systemImage: category.systemImage,
                            isSelected: selectedCategory == category
                        ) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var tasksSection: some View {
        Section("Tasks (\(filteredTasks.count))") {
            ForEach(filteredTasks) { task in
                NavigationLink(value: task) {
                    TaskRowView(task: task)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        PasteboardService.copy(task.prompt)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)

                    Button {
                        // Add to favorites - could be implemented later
                    } label: {
                        Label("Favorite", systemImage: "star")
                    }
                    .tint(.yellow)
                }
            }
        }
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.15),
                    in: .capsule
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    isSelected ? nil : Capsule()
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: BenchmarkTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title)
                    .font(.headline)

                Spacer()

                HStack(spacing: 6) {
                    DifficultyBadge(difficulty: task.difficulty)

                    if task.hasTests {
                        Label(
                            task.usesIOTesting ? "IO" : "XT",
                            systemImage: task.usesIOTesting ? "arrow.left.arrow.right" : "checkmark.circle"
                        )
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(4)
                        .background(Color.green.opacity(0.15), in: .circle)
                    }
                }
            }

            HStack {
                Label(task.category.displayName, systemImage: task.category.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !task.prompt.isEmpty {
                    Label("\(task.prompt.count) chars", systemImage: "text.alignleft")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(task.prompt.prefix(100) + (task.prompt.count > 100 ? "..." : ""))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: TaskDifficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(difficultyColor.opacity(0.15), in: .capsule)
            .foregroundStyle(difficultyColor)
    }

    private var difficultyColor: Color {
        switch difficulty {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        }
    }
}

#Preview {
    TaskBrowserView()
}

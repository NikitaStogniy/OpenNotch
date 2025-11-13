//
//  TodoListModule.swift
//  Notch
//
//  Created for OpenNotch
//

import SwiftUI
import SwiftData

class TodoListModule: NotchModule {
    let id = "todolist"
    let name = "To-Do List"
    let icon = "checklist"
    let miniIcon = "checklist"
    let side: ModuleSide = .left
    @AppStorage("todoListModuleEnabled") var isEnabled: Bool = true
    let showInCollapsed = true
    let priority = 90

    func collapsedView() -> AnyView {
        AnyView(TodoCollapsedView())
    }

    func expandedView() -> AnyView {
        AnyView(TodoExpandedView())
    }
}

// MARK: - Collapsed View
struct TodoCollapsedView: View {
    @Query private var todos: [TodoItem]
    @StateObject private var settings = SettingsManager.shared

    var incompleteTasks: Int {
        todos.filter { !$0.isCompleted }.count
    }

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "checklist")
                .font(.system(size: 12))
                .foregroundColor(settings.getAccentColor())
            Text("\(incompleteTasks)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Expanded View
struct TodoExpandedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.dateCreated, order: .reverse) private var todos: [TodoItem]
    @StateObject private var settings = SettingsManager.shared
    @State private var newTaskText = ""

    var body: some View {
        ModuleExpandedLayout(icon: "checklist", title: "To-Do List") {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Add task input at top
                    HStack(spacing: 8) {
                        TextField("New task...", text: $newTaskText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .onSubmit {
                                addTask()
                            }
                        Button(action: addTask) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(newTaskText.isEmpty ? .gray : settings.getAccentColor())
                        }
                        .buttonStyle(.plain)
                        .disabled(newTaskText.isEmpty)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)

                    // Empty state or task list
                    if todos.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.3))
                            Text("No tasks")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Actual tasks
                        ForEach(todos) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: { toggleTask(todo) },
                                onDelete: { deleteTask(todo) }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            performDailyCleanup()
        }
    }

    private func addTask() {
        guard !newTaskText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newTodo = TodoItem(title: newTaskText.trimmingCharacters(in: .whitespaces))
        modelContext.insert(newTodo)
        newTaskText = ""
    }

    private func toggleTask(_ todo: TodoItem) {
        todo.isCompleted.toggle()
    }

    private func deleteTask(_ todo: TodoItem) {
        modelContext.delete(todo)
    }

    // Daily cleanup: Remove completed tasks from previous days
    private func performDailyCleanup() {
        let lastCleanupKey = "todoListLastCleanup"
        let today = Calendar.current.startOfDay(for: Date())

        // Get last cleanup date
        if let lastCleanupTimestamp = UserDefaults.standard.object(forKey: lastCleanupKey) as? TimeInterval {
            let lastCleanupDate = Date(timeIntervalSince1970: lastCleanupTimestamp)
            let lastCleanupDay = Calendar.current.startOfDay(for: lastCleanupDate)

            // If it's a new day, perform cleanup
            if today > lastCleanupDay {
                cleanupCompletedTasks()
                UserDefaults.standard.set(today.timeIntervalSince1970, forKey: lastCleanupKey)
            }
        } else {
            // First time running, just set the date
            UserDefaults.standard.set(today.timeIntervalSince1970, forKey: lastCleanupKey)
        }
    }

    private func cleanupCompletedTasks() {
        // Delete all completed tasks
        let completedPredicate = #Predicate<TodoItem> { todo in
            todo.isCompleted == true
        }

        do {
            try modelContext.delete(model: TodoItem.self, where: completedPredicate)
            print("✅ Daily cleanup: Removed completed tasks")
        } catch {
            print("❌ Failed to cleanup completed tasks: \(error.localizedDescription)")
        }
    }
}

// MARK: - Todo Row
struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(todo.isCompleted ? settings.getAccentColor() : .white.opacity(0.3))
            }
            .buttonStyle(.plain)

            // Task title
            Text(todo.title)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .strikethrough(todo.isCompleted)
                .opacity(todo.isCompleted ? 0.5 : 1.0)
                .lineLimit(2)

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}

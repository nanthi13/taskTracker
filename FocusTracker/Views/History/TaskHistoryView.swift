// Created by: nanthi13 on 20/01/2026

import SwiftUI

/// Displays previously completed focus sessions and allows deletion.
/// - Groups tasks by day with section headers (Today, Yesterday, or date).
/// - Exposes a "Clear All" destructive action with confirmation.
/// - Presents a task detail sheet when a row is tapped.
struct TaskHistoryView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showClearAlert = false
    @State private var selectedTask: PomodoroTaskModel? = nil

    private var calendar: Calendar { .current }

    /// Tasks grouped by start-of-day, sorted with most recent day first.
    /// Each section’s tasks are sorted by time descending (most recent first).
    private var groupedTasks: [(day: Date, tasks: [PomodoroTaskModel])] {
        let groups = Dictionary(grouping: dataManager.tasks) { task in
            calendar.startOfDay(for: task.date)
        }

        let sortedDays = groups.keys.sorted(by: >) // most recent day first
        return sortedDays.map { day in
            let tasks = (groups[day] ?? []).sorted(by: { $0.date > $1.date })
            return (day: day, tasks: tasks)
        }
    }

    var body: some View {
        List {
            if dataManager.tasks.isEmpty {
                Section {
                    Text("No tasks yet.")
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                ForEach(groupedTasks, id: \.day) { section in
                    Section(header: Text(sectionHeader(for: section.day))) {
                        ForEach(section.tasks) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.name)
                                    .font(.headline)
                                Text("Focused for \(timeString(from: task.duration)) on \(task.date.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("taskRow_\(task.name)")
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTask = task }
                        }
                        // Map delete offsets to underlying indices in dataManager.tasks
                        .onDelete { offsets in
                            deleteTasks(in: section.day, offsets: offsets)
                        }
                    }
                }
            }
        }
        .monospaced()
        .accessibilityIdentifier("taskHistoryList")
        .navigationTitle("Task History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .accessibilityIdentifier("clearAllButton")
                .disabled(dataManager.tasks.isEmpty)
            }
        }
        .alert("Clear all tasks?", isPresented: $showClearAlert) {
            Button("Delete All", role: .destructive) {
                dataManager.clearAllTasks()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        // Present the TaskDetailView as a sheet.
        .taskDetailSheet(selectedTask: $selectedTask)
    }

    // MARK: - Helpers

    /// Formats seconds as mm:ss.
    func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Section header label: Today, Yesterday, or full date.
    private func sectionHeader(for day: Date) -> String {
        if calendar.isDateInToday(day) {
            return "Today"
        } else if calendar.isDateInYesterday(day) {
            return "Yesterday"
        } else {
            return day.formatted(.dateTime.month(.abbreviated).day().year())
        }
    }

    /// Deletes tasks at offsets within a given day section, mapping to indices in dataManager.tasks.
    private func deleteTasks(in day: Date, offsets: IndexSet) {
        let startOfDay = calendar.startOfDay(for: day)
        // Build the list of tasks for that day in the same order shown (date descending).
        let sectionTasks = dataManager.tasks
            .filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
            .sorted(by: { $0.date > $1.date })

        // Map the offsets to the concrete tasks being deleted.
        let tasksToDelete = offsets.compactMap { index in
            sectionTasks.indices.contains(index) ? sectionTasks[index] : nil
        }

        // Translate to indices in the master array and remove.
        for task in tasksToDelete {
            dataManager.removeTask(task)
        }
    }
}

#Preview {
    let mockData = DataManager()
    mockData.tasks = [
        PomodoroTaskModel(name: "Design UI", duration: 25 * 60, date: Date().addingTimeInterval(-3600)),
        PomodoroTaskModel(name: "Write Documentation", duration: 15 * 60, date: Date().addingTimeInterval(-7200)),
        PomodoroTaskModel(name: "Debug Timer", duration: 10 * 60, date: Date().addingTimeInterval(-10800)),
        PomodoroTaskModel(name: "Yesterday Task", duration: 20 * 60, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        PomodoroTaskModel(name: "Last Week Task", duration: 30 * 60, date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
    ]
    return NavigationStack {
        TaskHistoryView(dataManager: mockData)
            .accessibilityIdentifier("taskHistoryList")
    }
}

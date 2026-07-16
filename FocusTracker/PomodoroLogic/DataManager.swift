// Created by: nanthi13 on 20/01/2026

import Foundation
import SwiftUI
internal import Combine

/// MainActor observable store for Pomodoro tasks with simple persistence.
/// - Persists tasks to UserDefaults as JSON.
/// - Provides convenience methods to add/remove/update tasks.
/// - Includes mock data loaders for previews/testing.
@MainActor
class DataManager: ObservableObject {

    @Published var tasks: [PomodoroTaskModel] = []

    private let tasksKey = "pomodoro_tasks"

    init() {
        loadTasks()
        #if DEBUG
        if tasks.isEmpty {
            // Seed mock data for development previews/analytics.
            loadMockDataSpanningWeeks(weeks: 20)
        }
        #endif
    }

    /// Adds a new task and persists the updated list.
    func addTask(name: String, duration: Int) {
        let task = PomodoroTaskModel(name: name, duration: duration, date: Date())
        tasks.append(task)
        saveTasks()
    }

    func removeTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }

    func removeTask(_ task: PomodoroTaskModel) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    /// Updates an existing task (e.g., rename) and persists.
    func updateTask(_ updated: PomodoroTaskModel) {
        if let idx = tasks.firstIndex(where: { $0.id == updated.id }) {
            tasks[idx] = updated
            saveTasks()
        }
    }

    /// Clears all tasks and persists.
    func clearAllTasks() {
        tasks.removeAll()
        saveTasks()
    }

    // MARK: - Persistence

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }

    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([PomodoroTaskModel].self, from: data) {
            tasks = decoded
        }
    }

    // MARK: - Mock data

    func loadMockData() {
        tasks = [
            PomodoroTaskModel(name: "Design UI", duration: 600, date: Date().addingTimeInterval(-3000)),
            PomodoroTaskModel(name: "Finish Documentation", duration: 600, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Clean up UI", duration: 600, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 600, date: Date().addingTimeInterval(-6000))
        ]
        saveTasks()
    }
    
    /// Generates multiple tasks per day across a span of weeks.
    /// - Parameters:
    ///   - weeks: Number of past weeks to generate (inclusive of today). Defaults to 2.
    ///   - tasksPerDay: How many tasks to create for each day. Defaults to 4 (matching prior behavior).
    ///   - replaceExisting: If true, replaces the current tasks array; otherwise appends. Defaults to false so this can be used together with other loaders.
    ///   - durationRange: Random duration range in seconds for each generated task. Defaults to 600...1800.
    ///   - baseNames: Optional pool of names to cycle through for generated tasks.
    func loadMultipleTasksForSameDay(
        weeks: Int = 2,
        tasksPerDay: Int = 4,
        replaceExisting: Bool = false,
        durationRange: ClosedRange<Int> = 600...1800,
        baseNames: [String] = [
            "Design UI", "Finish Documentation", "Clean up UI", "Simplify code",
            "Code Review", "Refactor Module", "Fix Bugs", "Write Tests"
        ]
    ) {
        let days = max(0, weeks) * 7
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var generated: [PomodoroTaskModel] = []

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            // Create multiple tasks that all share the same date (startOfDay),
            // mimicking "multiple sessions on the same day".
            for i in 0..<max(1, tasksPerDay) {
                let name = baseNames[(i + offset) % baseNames.count]
                let duration = Int.random(in: durationRange)

                // Optionally vary the time within the day to have nicer charts,
                // but keep the same day. We'll add a small hour/minute offset.
                var components = DateComponents()
                components.hour = 9 + ((i * 2) % 8) // distribute between 9:00 and ~23:00
                components.minute = (i * 7) % 60

                let dateInDay = calendar.date(bySettingHour: components.hour ?? 9,
                                              minute: components.minute ?? 0,
                                              second: 0,
                                              of: day) ?? day

                generated.append(PomodoroTaskModel(name: name, duration: duration, date: dateInDay))
            }
        }

        if replaceExisting {
            tasks = generated.sorted { $0.date < $1.date }
        } else {
            tasks.append(contentsOf: generated)
            tasks.sort { $0.date < $1.date }
        }
        saveTasks()
    }

    /// Loads mock data with fixed dates for deterministic charts/tests.
    func loadMockDataWithDate() {
        tasks = [
            PomodoroTaskModel(name: "Design UI", duration: 600, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 24))!),
            PomodoroTaskModel(name: "Finish Documentation", duration: 600, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 25))!),
            PomodoroTaskModel(name: "Clean up UI", duration: 600, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 26))!),
            PomodoroTaskModel(name: "Simplify code", duration: 600, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 27))!),
            PomodoroTaskModel(name: "Design UI", duration: 1500, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 28))!),
            PomodoroTaskModel(name: "Finish Documentation", duration: 1200, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 29))!),
            PomodoroTaskModel(name: "Clean up UI", duration: 1200, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 30))!),
            PomodoroTaskModel(name: "Simplify code", duration: 1200, date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 31))!),
            PomodoroTaskModel(name: "UI testing", duration: 1400, date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 5))!),
            PomodoroTaskModel(name: "See if task is visible in test", duration: 1600, date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 4))!),
            PomodoroTaskModel(name: "Simplify code", duration: 1700, date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!),
            PomodoroTaskModel(name: "Simplify code", duration: 1800, date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 2))!),
            PomodoroTaskModel(name: "Design UI", duration: 600, date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 3))!)
        ]
        saveTasks()
    }

    /// Loads mock data spanning a number of weeks for analytics exploration.
    func loadMockDataSpanningWeeks(weeks: Int) {
        let days = weeks * 7
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var generatedTasks: [PomodoroTaskModel] = []

        for offset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let task = PomodoroTaskModel(
                    name: "Mock Task \(days - offset)",
                    duration: Int.random(in: 600...1800),
                    date: date
                )
                generatedTasks.append(task)
            }
        }

        tasks = generatedTasks.sorted { $0.date < $1.date }
        saveTasks()
    }
}


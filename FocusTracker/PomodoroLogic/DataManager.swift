//CREATED  BY: nanthi13 ON 20/01/2026

import Foundation
import SwiftUI
internal import Combine



// persistent storage for tasks
@MainActor
class DataManager: ObservableObject {
    
    @Published var tasks: [PomodoroTaskModel] = []
    
    private let tasksKey = "pomodoro_tasks"
    
    init() {
        loadTasks()
        
        #if DEBUG
        if tasks.isEmpty {
            // set up mock data for testing
            loadMockDataSpanningWeeks(weeks: 20)
        }
        #endif
    }
    
    
    
    // add task to persistent storage
    func addTask(name: String, duration: Int) {
        let task = PomodoroTaskModel(name: name, duration: duration, date: Date())
        tasks.append(task)
        print("✅ TASK ADDED:", name)
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
    
    func clearAllTasks() {
        tasks.removeAll()
        saveTasks()
    }
    
    // save function
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    // load function
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([PomodoroTaskModel].self, from: data) {
            tasks = decoded
        }
    }
    
    func loadMockData() {
        tasks = [
            PomodoroTaskModel(name: "Design UI", duration: 600, date: Date().addingTimeInterval(-3000)),
            PomodoroTaskModel(name: "Finish Documentation", duration: 600, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Clean up UI", duration: 600, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 600, date: Date().addingTimeInterval(-6000))
        ]
        saveTasks()
    }
    
    // testFocusTaskIsLoggedInTaskHistory fails if this function is used instead of loadMockData
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
            PomodoroTaskModel(name: "Simplify code", duration: 1800, date:
                                Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 2))!),
            PomodoroTaskModel(name: "Design UI", duration: 600,date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 3))!
            )
        ]
        saveTasks()
    }
    
    // used for testing weekly analytics with a wider date range (spanning x weeks)
    func loadMockDataSpanningWeeks(weeks: Int) {
        let days = weeks * 7
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var generatedTasks: [PomodoroTaskModel] = []
        
        // Go back x days + today and create a task for each day
        for offset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                
                let task = PomodoroTaskModel(
                    name: "Mock Task \(offset + 1)",
                    duration: Int.random(in: 600...1800), // 10–30 min
                    date: date
                )
                
                generatedTasks.append(task)
            }
        }
        
        // Optional: sort chronologically (oldest first)
        tasks = generatedTasks.sorted { $0.date < $1.date }
        
        saveTasks()
    }

}

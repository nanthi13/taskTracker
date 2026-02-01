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
            loadMockData()
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
            PomodoroTaskModel(name: "Design UI", duration: 1500, date: Date().addingTimeInterval(-3000)),
            PomodoroTaskModel(name: "Finish Documentation", duration: 1200, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Clean up UI", duration: 1200, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 1200, date: Date().addingTimeInterval(-6000))
        ]
        saveTasks()
    }
    
    // testFocusTaskIsLoggedInTaskHistory fails if this function is used instead of loadMockData
    func loadMoreMockData() {
        tasks = [
            PomodoroTaskModel(name: "Design UI", duration: 1500, date: Date().addingTimeInterval(-3000)),
            PomodoroTaskModel(name: "Finish Documentation", duration: 1200, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Clean up UI", duration: 1200, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 1200, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "UI testing", duration: 1400, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "See if task is visible in test", duration: 1600, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 1700, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 1800, date: Date().addingTimeInterval(-6000)),
            PomodoroTaskModel(name: "Simplify code", duration: 1200, date: Date().addingTimeInterval(-6000))

        ]
        saveTasks()
    }
}

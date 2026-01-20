//CREATED  BY: nanthi13 ON 20/01/2026

import SwiftUI

import SwiftUI
struct TaskHistoryView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showClearAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Previous Tasks")) {
                if dataManager.tasks.isEmpty {
                    Text("No tasks yet.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(Array(dataManager.tasks.enumerated()), id: \.element.id) {index, task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.name)
                                .font(.headline)
                            Text("Focused for \(timeString(from: task.duration)) on \(task.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteTask)
                }
                
            }
        }
        .navigationTitle("Task History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
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
    }
    
    func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    func deleteTask(at offsets: IndexSet) {
        dataManager.removeTask(at: offsets)
    }
}

#Preview {
    let mockData = DataManager()
    
    mockData.tasks = [
        PomodoroTaskModel(name: "Design UI", duration: 25 * 60, date: Date().addingTimeInterval(-3600)),
        PomodoroTaskModel(name: "Write Documentation", duration: 15 * 60, date: Date().addingTimeInterval(-7200)),
        PomodoroTaskModel(name: "Debug Timer", duration: 10 * 60, date: Date().addingTimeInterval(-10800))
        
    ]
    
    return NavigationStack {
        TaskHistoryView(dataManager: mockData)
    }
}

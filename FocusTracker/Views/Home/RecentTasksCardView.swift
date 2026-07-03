// Created by: nanthi13 on 29/01/2026

import SwiftUI

/// Compact card showing the three most recent tasks with a quick link to History.
/// Tapping a task presents its detail sheet.
struct RecentTasksCardView: View {

    @ObservedObject var dataManager: DataManager
    @Binding var selectedTab: AppTab
    @State private var selectedTask: PomodoroTaskModel? = nil

    /// Three most recent tasks by date descending.
    private var recentThree: [PomodoroTaskModel] {
        dataManager.tasks.sorted(by: { $0.date > $1.date }).prefix(3).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Tasks")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)

            if dataManager.tasks.isEmpty {
                Text("No tasks yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(recentThree) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Focused for \(timeString(from: task.duration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(task.date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selectedTask = task }
                }

                Button("See All") {
                    selectedTab = .history
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
        // Present TaskDetailView as a sheet.
        .taskDetailSheet(selectedTask: $selectedTask)
    }

    /// Formats seconds as mm:ss.
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    // Covered in HomeView/AppView previews.
}


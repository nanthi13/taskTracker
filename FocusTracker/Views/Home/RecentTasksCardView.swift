//CREATED  BY: nanthi13 ON 29/01/2026

import SwiftUI

struct RecentTasksCardView: View {

    @ObservedObject var dataManager: DataManager
    @Binding var selectedTab: AppTab
    @State private var selectedTask: PomodoroTaskModel? = nil

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
                // Show up to 3 most recent tasks
                ForEach(dataManager.tasks.sorted(by: { $0.date > $1.date }).prefix(3)) { task in
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
                    .onTapGesture {
                        selectedTask = task
                    }
                }

                // Optional "See All" button
                Button("See All") {
                    selectedTab = .history
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
        // Present TaskDetailView as a sheet instead of overlay
        .taskDetailSheet(selectedTask: $selectedTask)

    }

    // Helper
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
//    RecentTasksCardView()
}

//CREATED  BY: nanthi13 ON 09/02/2026

import Foundation
import SwiftUI

// reusable code to represent the task detail sheet, used in  analytics, recenttasks and task list
struct TaskDetailSheetModifier: ViewModifier {
    @Binding var selectedTask: PomodoroTaskModel?
    @EnvironmentObject var dataManager: DataManager

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedTask) { task in
                TaskDetailView(
                    task: task,
                    onClose: {
                        selectedTask = nil
                    },
                    dataManager: dataManager
                )
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func taskDetailSheet(
        selectedTask: Binding<PomodoroTaskModel?>
    ) -> some View {
        modifier(TaskDetailSheetModifier(selectedTask: selectedTask))
    }
}

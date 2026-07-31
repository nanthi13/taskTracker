//CREATED  BY: nanthi13 ON 09/02/2026

import Foundation
import SwiftUI

// Reusable code to present either TaskDetailView (for a selected task)
// or DaySessionsDetailView (for a selected day) in the same sheet overlay.
struct TaskDetailSheetModifier: ViewModifier {
    @Binding var selectedTask: PomodoroTaskModel?
    @Binding var selectedDay: Date?
    let tasks: [PomodoroTaskModel]

    @EnvironmentObject var dataManager: DataManager

    // Single source of truth for sheet presentation: presented if either binding is non-nil.
    private var isPresented: Binding<Bool> {
        Binding(
            get: { selectedTask != nil || selectedDay != nil },
            set: { presenting in
                if presenting == false {
                    selectedTask = nil
                    selectedDay = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented) {
                // Decide which content to show
                if let task = selectedTask {
                    TaskDetailView(
                        task: task,
                        onClose: {
                            selectedTask = nil
                            selectedDay = nil
                        },
                        dataManager: dataManager
                    )
                    .presentationDetents([.fraction(0.45)])
                    .presentationDragIndicator(.visible)
                } else if let day = selectedDay {
                    // TaskDetailView-like presentation for Day Sessions inside the shared overlay.
                    DaySessionsContainer(
                        day: Calendar.current.startOfDay(for: day),
                        tasks: tasks,
                        onClose: {
                            selectedTask = nil
                            selectedDay = nil
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(false)
                } else {
                    // Fallback (shouldn’t happen): dismiss.
                    EmptyView()
                        .onAppear {
                            selectedTask = nil
                            selectedDay = nil
                        }
                }
            }
    }
}

// MARK: - DaySessionsContainer (styled like TaskDetailView)

private struct DaySessionsContainer: View {
    let day: Date
    let tasks: [PomodoroTaskModel]
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header (matches TaskDetailView style) on a transparent background.
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day Sessions")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(day.formatted(.dateTime.weekday(.wide).month().day().year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("daySessionsCloseButton")
            }
            .padding(.horizontal)

            // Main card (mirrors TaskDetailView card background and shadow)
            VStack(spacing: 12) {
                // We pass a concise title to avoid double “Day Sessions” headers inside.
                DaySessionsDetailView(
                    title: "Sessions",
                    tasks: tasks,
                    anchorDate: day
                )
                .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        // Match TaskDetailView’s vertical breathing room and keep header area transparent.
        .padding(.vertical)
        
    }
}

extension View {
    // Backward-compatible API for existing callers that only use selectedTask.
    func taskDetailSheet(
        selectedTask: Binding<PomodoroTaskModel?>
    ) -> some View {
        // Default to no selected day and no tasks list; this keeps prior behavior.
        modifier(TaskDetailSheetModifier(selectedTask: selectedTask, selectedDay: .constant(nil), tasks: []))
    }

    func taskDetailSheet(
        selectedTask: Binding<PomodoroTaskModel?>,
        selectedDay: Binding<Date?>,
        tasks: [PomodoroTaskModel]
    ) -> some View {
        modifier(TaskDetailSheetModifier(selectedTask: selectedTask, selectedDay: selectedDay, tasks: tasks))
    }
}


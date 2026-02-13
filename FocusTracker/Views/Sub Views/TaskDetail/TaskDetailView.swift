//CREATED  BY: nanthi13 ON 08/02/2026

import SwiftUI

struct TaskDetailView: View {
    let task: PomodoroTaskModel
    var onClose: (() -> Void)?
    @ObservedObject var dataManager: DataManager
    @State private var showDeleteConfirmation: Bool = false
    @State private var isEditing: Bool = false
    @State private var editedName: String = ""

    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 {
            return "\(m) min"
        } else if m == 0 {
            return "\(s) sec"
        } else {
            return "\(m) min \(s) sec"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Task Details")
                    .font(.headline)
                Spacer()
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("taskDetailCloseButton")
            }
            HStack {
                // Title and edit/delete buttons on the same row
                if isEditing {
                    TextField("Task name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                } else {
                    Text(task.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }

                Spacer()

                if isEditing {
                    Button {
                        // Cancel editing
                        isEditing = false
                        editedName = task.name
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Save changes: update task, then auto-close sheet
                        var updated = task
                        updated.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !updated.name.isEmpty {
                            dataManager.updateTask(updated)
                            // auto-close the sheet after successful save
                            onClose?()
                        }
                        isEditing = false
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("taskSaveButton")
                } else {
                    Button {
                        // enter edit mode
                        editedName = task.name
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("taskEditButton")

                    Button(role: .destructive) {
                        // show confirmation instead of deleting immediately
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("taskDeleteButton")
                }
            }
            HStack(spacing: 10) {
                Label(timeString(from: task.duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Divider()
                    .frame(height: 14)
                Text(task.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.black).opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("taskDetailCard_\(task.id.uuidString)")
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                dataManager.removeTask(task)
                // close the sheet / view after deletion
                onClose?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(task.name)\"? This action cannot be undone.")
        }
        .onAppear {
            editedName = task.name
        }
    }
}

// MARK: - Preview

#Preview {
    let dataManager = DataManager()
    let sample = PomodoroTaskModel(name: "Write Unit Tests", duration: 25 * 60, date: Date())
    TaskDetailView(task: sample, onClose: {}, dataManager: dataManager)
        .padding()
}

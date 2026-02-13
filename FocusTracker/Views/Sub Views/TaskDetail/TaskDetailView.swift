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
        VStack(spacing: 16) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Task Details")
                        .font(.headline)
                    Text("Quick view and actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Close button
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("taskDetailCloseButton")
            }
            .padding(.horizontal)
            
            // Main card
            VStack(spacing: 12) {
                // Title / Edit row
                HStack(alignment: .top) {
                    if isEditing {
                        TextField("Task name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .accessibilityIdentifier("taskNameTextField")
                    } else {
                        Text(task.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }

                    Spacer()

                    if isEditing {
                        // Save / Cancel stacked vertically on compact space
                        VStack(spacing: 8) {
                            Button(action: {
                                // Save changes: update task, then auto-close sheet
                                let newName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !newName.isEmpty {
                                    var updated = task
                                    updated.name = newName
                                    dataManager.updateTask(updated)
                                    // auto-close the sheet after successful save
                                    onClose?()
                                }
                                isEditing = false
                            }) {
                                Text("Save")
                                    .frame(minWidth: 72)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("taskSaveButton")

                            Button(action: {
                                // Cancel editing
                                withAnimation { isEditing = false }
                                editedName = task.name
                            }) {
                                Text("Cancel")
                                    .frame(minWidth: 72)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        // Action icons: edit + delete
                        HStack(spacing: 10) {
                            Button(action: {
                                // enter edit mode
                                editedName = task.name
                                withAnimation { isEditing = true }
                            }) {
                                Image(systemName: "pencil")
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("taskEditButton")

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("taskDeleteButton")
                        }
                    }
                }
                
                // Metadata row
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(timeString(from: task.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(task.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Spacer()
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .animation(.default, value: isEditing)
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

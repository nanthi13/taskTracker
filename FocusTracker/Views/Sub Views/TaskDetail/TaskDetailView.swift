//CREATED  BY: nanthi13 ON 08/02/2026

import SwiftUI

struct TaskDetailView: View {
    let task: PomodoroTaskModel
    var onClose: (() -> Void)?

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

            Text(task.name)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(2)

            HStack(spacing: 10) {
                Label(timeString(from: task.duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Divider()
                    .frame(height: 14)
                Text(task.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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
}

// MARK: - Preview

#Preview {
    let sample = PomodoroTaskModel(name: "Write Unit Tests", duration: 25 * 60, date: Date())
    return TaskDetailView(task: sample, onClose: {})
        .padding()
}

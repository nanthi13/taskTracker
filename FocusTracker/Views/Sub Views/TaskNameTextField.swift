// Created by: nanthi13 on 28/01/2026

import SwiftUI

/// Styled text field for entering a task name.
/// - Highlights when focused
/// - Rounded rectangle background with subtle stroke animation
struct TaskNameTextField: View {
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Enter task name", text: $text)
            .focused($isFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isFocused ? Color(.systemGray5) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? Color.blue : Color(.systemGray3), lineWidth: isFocused ? 3 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .padding(.horizontal)
    }
}


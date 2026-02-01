//CREATED  BY: nanthi13 ON 28/01/2026

import SwiftUI

// custom textfield 
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
            // highlight animation
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .padding(.horizontal)
        
        
        
    }
}


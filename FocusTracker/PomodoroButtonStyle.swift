//CREATED  BY: nanthi13ON 20/01/2026

import Foundation
import SwiftUI

struct PomodoroButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 100, height: 50)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

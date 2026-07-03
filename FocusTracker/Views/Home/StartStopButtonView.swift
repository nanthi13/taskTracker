// Created by: nanthi13 on 20/01/2026

import SwiftUI

/// Dynamic control row that switches between Start, Pause/Reset, and Resume/Reset
/// based on the timer state. Also scrolls back to the timer section on Start.
struct StartStopButtonsView: View {
    let state: TimerManager.TimerState

    let start: () -> Void
    let pause: () -> Void
    let reset: () -> Void
    let resume: () -> Void
    let endSession: () -> Void
    var scrollProxy: ScrollViewProxy

    var body: some View {
        HStack(spacing: 30) {
            switch state {
            case .idle:
                Button("Start") {
                    start()
                    withAnimation(.easeInOut) {
                        scrollProxy.scrollTo("focusTime", anchor: .top)
                    }
                }
                .buttonStyle(PomodoroButtonStyle(color: .green))
                .accessibilityIdentifier("startButton")
                .clipShape(RoundedRectangle(cornerRadius: 100))

            case .running:
                Button("Pause", action: pause)
                    .buttonStyle(PomodoroButtonStyle(color: .teal))
                    .accessibilityIdentifier("pauseButton")
                Button("Reset", action: reset)
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("resetButton")

            case .paused:
                Button("Resume", action: resume)
                    .buttonStyle(PomodoroButtonStyle(color: .green))
                    .accessibilityIdentifier("resumeButton")
                Button("End Session", action: endSession)
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("endSessionButton")
                    
                Button("Reset", action: reset)
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("resetButton")
                
            }
        }
        .animation(.easeInOut, value: state)
    }
}

// Note: PomodoroButtonStyle is assumed to be defined elsewhere in the project.


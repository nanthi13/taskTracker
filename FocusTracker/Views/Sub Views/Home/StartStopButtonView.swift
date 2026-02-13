//CREATED  BY: nanthi13 ON 20/01/2026

import SwiftUI

// dynamic button layout
struct StartStopButtonsView: View {
    let state: TimerManager.TimerState
    
    let start: () -> Void
    let pause: () -> Void
    let reset: () -> Void
    let resume: () -> Void
    var scrollProxy: ScrollViewProxy
    
    var body: some View{
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
                // resume does the same as start !
                Button("Resume", action: resume)
                    .buttonStyle(PomodoroButtonStyle(color: .green))
                    .accessibilityIdentifier("resumeButton")
                Button("Reset", action: reset)
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("resetButton")
            }
        }
        .animation(.easeInOut, value: state)
    }
}

//#Preview {
//    let dataManager = DataManager()
//    let timerManager = TimerManager(dataManager: dataManager)
//    StartStopButtonsView(state: timerManager.state, start: timerManager.startTimer, pause: timerManager.pauseTimer, reset: timerManager.resetTimer, resume: timerManager.resumeTimer, scrollProxy: proxy)
//}


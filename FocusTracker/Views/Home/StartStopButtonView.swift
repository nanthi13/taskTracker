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
                //TODO: Change to names to symbols
                HStack(spacing: 0) {
                    Button{
                        pause()
                        // action pause
                    }
                    label: {
                        Image(systemName: "pause")
                            .font(.system(size: 40))
                            .frame(width: 40, height: 40)

                            
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .yellow))
                    .accessibilityIdentifier("pauseButton")
                    //.clipShape(RoundedRectangle(cornerRadius: 100))
                    
                    Button {
                        endSession()
                    }
                    label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 35))
                            .frame(width: 40, height: 40)
                           
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("resetButton")
                    //.clipShape(RoundedRectangle(cornerRadius: 100))
                    
                    
                }
                .clipShape(RoundedRectangle(cornerRadius: 100))
                
            case .paused:
                HStack(spacing: 0){
                    Button {
                        resume()
                    }
                    label: {
                        Image(systemName: "play")
                            .font(.system(size: 40))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .green))
                    .accessibilityIdentifier("resumeButton")
                    //.clipShape(RoundedRectangle(cornerRadius: 100))
                    
                    Button {
                        endSession()
                    }
                    label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 40))
                            .frame(width: 40, height: 40)
                           
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("endSessionButton")
                    //.clipShape(RoundedRectangle(cornerRadius: 100))
                    
                    Button {
                        reset()
                    }
                    label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 35))
                            .frame(width: 40, height: 40)
                            
                    }
                    .buttonStyle(PomodoroButtonStyle(color: .red))
                    .accessibilityIdentifier("resetButton")
                    //.clipShape(RoundedRectangle(cornerRadius: 100))
                    
//                    Button("Resume", action: resume)
//                        .buttonStyle(PomodoroButtonStyle(color: .green))
//                        .accessibilityIdentifier("resumeButton")
//                    
//                    Button("End Session", action: endSession)
//                        .buttonStyle(PomodoroButtonStyle(color: .red))
//                        .accessibilityIdentifier("endSessionButton")
//                    
//                    Button("Reset", action: reset)
//                        .buttonStyle(PomodoroButtonStyle(color: .red))
//                        .accessibilityIdentifier("resetButton")
                
                }
                .clipShape(RoundedRectangle(cornerRadius: 100))
            }
        }
        .animation(.smooth, value: state)
    }
}

// Note: PomodoroButtonStyle is assumed to be defined elsewhere in the project.


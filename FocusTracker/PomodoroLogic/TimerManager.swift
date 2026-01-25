//CREATED  BY: nanthi13 ON 20/01/2026

import Foundation
import SwiftUI
import AudioToolbox
internal import Combine

@MainActor
class TimerManager: ObservableObject {
    
    enum TimerState {
        case idle
        case running
        case paused
    }
    
    @Published private(set) var state: TimerState = .idle
    @Published var isRunning = false
    @Published var isBreak = false
    @Published var timeRemaining: Int = 25 * 60
    @Published var taskName: String = ""
    
    @Published var selectedFocusMinutes: Int
    @Published var selectedBreakMinutes: Int
    
    // progress animation
    @Published var animatedProgress: Double = 0
    
    var timer: Timer?
    private let dataManager: DataManager
    var focusDuration: Int { selectedFocusMinutes * 60 }
    var breakDuration: Int { selectedBreakMinutes * 60 }
    
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    
    init(dataManager: DataManager, focusMinutes: Int = 25, breakMinutes: Int = 5) {
        self.dataManager = dataManager
        self.selectedFocusMinutes = focusMinutes
        self.timeRemaining = focusMinutes * 60
        selectedBreakMinutes = breakMinutes
    }
    
    
    func startTimer() {
        guard !isRunning else { return }
        
        state = .running
        isRunning = true
        
        // Determine the duration: normal focus or short for UI test
        // sets the timer for 4 seconds when testing
        let duration = isUITesting ? 4 : focusDuration
        self.timeRemaining = duration

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    let total = self.isBreak ? self.breakDuration : duration
                    withAnimation(.linear(duration: 1.0)) {
                        self.animatedProgress = 1 - Double(self.timeRemaining) / Double(total)
                    }
                } else {
                    self.timer?.invalidate()
                    self.playSystemSound()
                    
                    if !self.isBreak {
                        self.finishFocusSession() // log the task
                    } else {
                        // break finished → start next focus
                        self.isBreak = false
                        self.timeRemaining = self.focusDuration
                        self.state = .idle
                        self.isRunning = false
                    }
                }
            }
        }
    }


    func pauseTimer() {
        state = .paused
        timer?.invalidate()
        isRunning = false
    }
    
    func resetTimer() {
        state = .idle
        timer?.invalidate()
        isRunning = false
        isBreak = false
        timeRemaining = focusDuration
    }
    
    // alert sound
    private func playSystemSound() {
        AudioServicesPlaySystemSound(1005)
    }
    
    // used for testing
    private func finishFocusSession() {
        timer?.invalidate()
        isRunning = false
        state = .idle
        
        dataManager.addTask(
            name: taskName.isEmpty ? "Unnamed Task" : taskName,
            duration: focusDuration
        )
        
        isBreak = true
        timeRemaining = breakDuration
        
        withAnimation(.easeInOut(duration: 0.5)) {
            animatedProgress = 0
        }
        
    }
    
    
    
}

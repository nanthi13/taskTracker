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
    
    enum TimerMode {
        case focus
        case breakTime
    }
    
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var mode: TimerMode = .focus
    
    
    @Published var timeRemaining: Int = 25 * 60
    @Published var taskName: String = ""
    
    @Published var selectedFocusMinutes: Int
    @Published var selectedBreakMinutes: Int
    
    // progress animation
    @Published var animatedProgress: Double = 0
    
    private var timer: Timer?
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
        guard state == .idle else { return }
        startCountDown()

    }
    
    func resumeTimer() {
        guard state == .paused else { return }
        startCountDown(resume: true)
    }
    
    // basic timer setup for starting and resuming
    private func startCountDown(resume: Bool = false) {
        state = .running
        
        let duration = currentDuration
        
        if !resume {
            timeRemaining = duration
            animatedProgress = 0
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                self.tick(totalDuration: duration)
            }
        }
    }
    
    private func tick(totalDuration: Int) {
        guard timeRemaining > 0 else {
            timer?.invalidate()
            handleTimerFinished()
            return
        }
        timeRemaining -= 1
        
        withAnimation(.linear(duration:1)) {
            animatedProgress = 1 - (Double(timeRemaining) / Double(totalDuration))
        }
    }
    
    private func handleTimerFinished() {
        playSystemSound()
        
        switch mode {
        case .focus:
            completeFocus()
            startBreakAutomatically()
            
        case .breakTime:
            completeBreak()
        }
    }
    
    private func completeFocus() {
        dataManager.addTask(name: taskName.isEmpty ? "Unnamed task" : taskName, duration: focusDuration)
    }
    
    private func completeBreak() {
        mode = .focus
        state = .idle
        timeRemaining = focusDuration
        animatedProgress = 0
        print("break finished")
    }
    
    // sets to proper mode and state, then starts countdown
    private func startBreakAutomatically() {
        mode = .breakTime
        state = .idle
        startCountDown()
    }
    
//    private func breakTimerFinished() {
//        self.isBreak = false
//        self.timeRemaining = self.focusDuration
//        self.state = .idle
//        self.isRunning = false
//        print("break finished")
//    }


    func pauseTimer() {
        // makes sure pause timer
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()

    }
    
    func resetTimer() {
        state = .idle
        timer?.invalidate()
        mode = .focus
        animatedProgress = 0
        timeRemaining = focusDuration
    }
    
    // helper
    private var currentDuration: Int {
        if isUITesting { return 6 }
        return mode == .focus ? focusDuration : breakDuration
    }
    
    // alert sound
    private func playSystemSound() {
        AudioServicesPlaySystemSound(1005)
    }
    
    
    
}

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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            _ in
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    let total = self.isBreak ? self.breakDuration : self.focusDuration
                    withAnimation(.linear(duration:1.0)) {
                        self.animatedProgress = 1 -
                        Double(self.timeRemaining) / Double(total)
                    }
                } else {
                    self.timer?.invalidate()
                    self.playSystemSound()
                    self.isRunning = false
                    self.state = .idle
                    
                    if !self.isBreak {
                        self.dataManager.addTask(name: self.taskName.isEmpty ? "Unnamed Task" : self.taskName, duration: self.focusDuration)
                    }
                    self.isBreak.toggle()
                    self.timeRemaining = self.isBreak ? self.breakDuration : self.focusDuration
                    
                    // reset timer animation
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.animatedProgress = 0
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
    
}

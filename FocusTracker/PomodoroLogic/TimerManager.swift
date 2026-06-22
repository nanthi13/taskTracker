//CREATED  BY: nanthi13 ON 20/01/2026

import Foundation
import SwiftUI
import AudioToolbox
internal import Combine
import UIKit
import UserNotifications
import ActivityKit
import WidgetKit

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

    /// The absolute end date for the current running countdown. We use this to
    /// recalculate remaining time when the app returns from background.
    private var endDate: Date?
    
    private static let notificationIdentifier = "pomodoro_timer_end"
    
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

        // Observe app lifecycle so we can reconcile the timer when returning from background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }
    
    func startTimer() async {
        guard state == .idle else { return }
        startCountDown()
        //startLiveActivity() ?t
        //#BUG: hardcoded value for timer
        let endDate = Date().addingTimeInterval(25*60)
        await LiveActivityManager.shared.startLiveActivity(endDate: endDate, type: .focusTime)
    }
    
  
    
    func resumeTimer() {
        guard state == .paused else { return }
        // When resuming, endDate will be set inside startCountDown using the current timeRemaining
        startCountDown(resume: true)
    }
    
    // basic timer setup for starting and resuming
    private func startCountDown(resume: Bool = false) {
        state = .running
        
        let intendedDuration = currentDuration
        
        if !resume {
            timeRemaining = intendedDuration
            animatedProgress = 0
        }

        // Calculate an absolute end date based on the current timeRemaining so we can recover after backgrounding
        endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        // Schedule a local notification to fire when the timer finishes (useful if the app is backgrounded)
        if let end = endDate {
            scheduleNotification(for: end)
        }
        
        restartTickingTimer(intendedDuration: intendedDuration)
    }
    
    private func restartTickingTimer(intendedDuration: Int) {
        timer?.invalidate()
        // Use a timer added to the common run loop mode so UI interactions don't pause it.
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick(intendedDuration: intendedDuration)
            }
        }
        self.timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    private func tick(intendedDuration: Int) {
        // Recalculate remaining time from the absolute endDate so the timer remains correct
        guard let end = endDate else {
            // Fallback to decrementing if endDate isn't available
            guard timeRemaining > 0 else {
                timer?.invalidate()
                handleTimerFinished()
                return
            }
            timeRemaining -= 1
            withAnimation(.linear(duration:1)) {
                animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
            }
            return
        }

        let newRemaining = max(0, Int(end.timeIntervalSinceNow))
        guard newRemaining > 0 else {
            timer?.invalidate()
            // Ensure timeRemaining shows 0 before finishing
            timeRemaining = 0
            animatedProgress = 1
            handleTimerFinished()
            return
        }

        timeRemaining = newRemaining
        withAnimation(.linear(duration:1)) {
            animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
        }
    }
    
    private func handleTimerFinished() {
        // Cancel any pending notification since we've completed while app is active
        cancelScheduledNotification()

        playSystemSound()
        
        switch mode {
        case .focus:
            completeFocus()
            startBreakAutomatically()
            
        case .breakTime:
            completeBreak()
        }
        // clear endDate when finished
        endDate = nil
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

    func pauseTimer() {
        // makes sure pause timer
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()

        // Compute remaining time from endDate and clear the endDate so resume uses the stored remaining
        if let end = endDate {
            timeRemaining = max(0, Int(end.timeIntervalSinceNow))
        }
        endDate = nil

        // Cancel scheduled notification because timer is paused
        cancelScheduledNotification()
    }
    
    func resetTimer() {
        state = .idle
        timer?.invalidate()
        mode = .focus
        animatedProgress = 0
        timeRemaining = focusDuration
        endDate = nil

        // Cancel any pending notification when resetting
        cancelScheduledNotification()
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

    // MARK: - Local notification helpers
    private func scheduleNotification(for endDate: Date) {
        let interval = endDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        // Avoid capturing UNUserNotificationCenter in @Sendable closures by calling .current() inside closures
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                Task { @MainActor in
                    self.createNotificationRequest(after: interval)
                }
            } else {
                // Request permission and schedule if granted
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        Task { @MainActor in
                            self.createNotificationRequest(after: interval)
                        }
                    }
                }
            }
        }
    }

    private func createNotificationRequest(after interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Focus complete"
        content.body = taskName.isEmpty ? "Your focus session has ended." : "\(taskName) has finished."
        content.sound = UNNotificationSound.default

        // Use a time-interval trigger so the notification fires even if the app is backgrounded
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)

        let request = UNNotificationRequest(identifier: TimerManager.notificationIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let err = error {
                print("Failed to schedule notification: \(err)")
            }
        }
    }

    private func cancelScheduledNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [TimerManager.notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [TimerManager.notificationIdentifier])
    }

    // MARK: - App lifecycle handlers
    @objc private func appWillResignActive(_ notification: Notification) {
        // Invalidate the UI timer; we will reconcile on return using endDate.
        timer?.invalidate()
    }

    @objc private func appDidBecomeActive(_ notification: Notification) {
        // When returning to the foreground, reconcile remaining time and restart the timer if necessary
        guard state == .running else { return }
        let intendedDuration = currentDuration
        if let end = endDate {
            let remaining = max(0, Int(end.timeIntervalSinceNow))
            if remaining <= 0 {
                // Timer finished while in the background
                timer?.invalidate()
                timeRemaining = 0
                animatedProgress = 1
                handleTimerFinished()
            } else {
                // Update timeRemaining and animatedProgress immediately for visual sync
                timeRemaining = remaining
                withAnimation(.linear(duration: 0.2)) {
                    animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
                }
                // restart the scheduled timer with fresh intendedDuration
                restartTickingTimer(intendedDuration: intendedDuration)
            }
        }
    }

}


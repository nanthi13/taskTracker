// Created by: nanthi13 on 20/01/2026

import Foundation
import SwiftUI
import AudioToolbox
internal import Combine
import UIKit
import UserNotifications

/// Coordinates focus/break countdowns, app lifecycle handling, and persistence.
/// - Uses an absolute endDate to recover accurate remaining time after backgrounding.
/// - Schedules a local notification to fire when the current session ends.
/// - Shortens durations under "UI_TESTING" to make UI tests deterministic.
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

    /// Remaining seconds in the current session.
    @Published var timeRemaining: Int = 25 * 60
    /// The current task name (cleared on break completion).
    @Published var taskName: String = ""

    /// Picker-controlled durations (minutes).
    @Published var selectedFocusMinutes: Int
    @Published var selectedBreakMinutes: Int

    /// Progress from 0...1 used by the ring animation.
    @Published var animatedProgress: Double = 0

    private var timer: Timer?
    private let dataManager: DataManager

    /// Absolute end time of the current countdown; used to reconcile after backgrounding.
    private var endDate: Date?

    private static let notificationIdentifier = "pomodoro_timer_end"

    /// Focus duration in seconds.
    var focusDuration: Int { selectedFocusMinutes * 60 }
    /// Break duration in seconds.
    var breakDuration: Int { selectedBreakMinutes * 60 }

    /// True when running under UI tests. Used to shorten durations.
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    init(dataManager: DataManager, focusMinutes: Int = 25, breakMinutes: Int = 5) {
        self.dataManager = dataManager
        self.selectedFocusMinutes = focusMinutes
        self.timeRemaining = focusMinutes * 60
        self.selectedBreakMinutes = breakMinutes

        // Observe app lifecycle to reconcile timing on return.
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }

    /// Starts a new session when idle.
    func startTimer() {
        guard state == .idle else { return }
        startCountDown()
    }

    /// Resumes a paused session.
    func resumeTimer() {
        guard state == .paused else { return }
        startCountDown(resume: true)
    }

    /// Core countdown starter for both fresh and resumed sessions.
    private func startCountDown(resume: Bool = false) {
        state = .running

        let intendedDuration = currentDuration

        if !resume {
            timeRemaining = intendedDuration
            animatedProgress = 0
        }

        // Establish an absolute end date for reliable background recovery.
        endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))

        // Schedule a local notification for session end.
        if let end = endDate {
            scheduleNotification(for: end)
        }

        restartTickingTimer(intendedDuration: intendedDuration)
    }

    /// Recreates the 1-second tick timer and attaches it to the common run loop.
    private func restartTickingTimer(intendedDuration: Int) {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick(intendedDuration: intendedDuration)
            }
        }
        self.timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    /// Recomputes remaining time from endDate and updates progress/finish state.
    private func tick(intendedDuration: Int) {
        guard let end = endDate else {
            // Fallback (should be rare): decrement until finish.
            guard timeRemaining > 0 else {
                timer?.invalidate()
                handleTimerFinished()
                return
            }
            timeRemaining -= 1
            withAnimation(.linear(duration: 1)) {
                animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
            }
            return
        }

        let newRemaining = max(0, Int(end.timeIntervalSinceNow))
        guard newRemaining > 0 else {
            timer?.invalidate()
            timeRemaining = 0
            animatedProgress = 1
            handleTimerFinished()
            return
        }

        timeRemaining = newRemaining
        withAnimation(.linear(duration: 1)) {
            animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
        }
    }

    /// Handles end-of-session behavior and transitions between modes.
    private func handleTimerFinished() {
        cancelScheduledNotification()
        playSystemSound()

        switch mode {
        case .focus:
            completeFocus()
            // Transition atomically into break using currentDuration (UI test override respected).
            mode = .breakTime
            timer?.invalidate()

            let intended = currentDuration
            timeRemaining = intended
            animatedProgress = 0

            endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
            if let end = endDate {
                scheduleNotification(for: end)
            }
            state = .running
            restartTickingTimer(intendedDuration: intended)

        case .breakTime:
            completeBreak()
        }
    }

    /// Logs a completed focus session.
    private func completeFocus() {
        dataManager.addTask(name: taskName.isEmpty ? "Unnamed task" : taskName, duration: focusDuration)
    }

    /// Resets state and returns to idle focus mode after a break finishes.
    private func completeBreak() {
        mode = .focus
        state = .idle
        timeRemaining = focusDuration
        animatedProgress = 0
        endDate = nil
        taskName = ""
    }

    /// Pauses an active session and cancels any pending notification.
    func pauseTimer() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()

        if let end = endDate {
            timeRemaining = max(0, Int(end.timeIntervalSinceNow))
        }
        endDate = nil
        cancelScheduledNotification()
    }

    /// Resets to idle focus mode and clears pending notifications.
    func resetTimer() {
        state = .idle
        timer?.invalidate()
        mode = .focus
        animatedProgress = 0
        timeRemaining = focusDuration
        endDate = nil
        cancelScheduledNotification()
    }

    /// Effective duration (seconds) for the current mode, shortened during UI tests.
    private var currentDuration: Int {
        if isUITesting { return 6 }
        return mode == .focus ? focusDuration : breakDuration
    }

    /// Plays a simple system sound on session completion.
    private func playSystemSound() {
        AudioServicesPlaySystemSound(1005)
    }

    // MARK: - Local notification helpers

    private func scheduleNotification(for endDate: Date) {
        let interval = endDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                Task { @MainActor in
                    self.createNotificationRequest(after: interval)
                }
            } else {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
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
        let intendedDuration = currentDuration

        if state == .running {
            if let end = endDate {
                let remaining = max(0, Int(end.timeIntervalSinceNow))
                if remaining <= 0 {
                    timer?.invalidate()
                    timeRemaining = 0
                    animatedProgress = 1
                    handleTimerFinished()
                } else {
                    timeRemaining = remaining
                    withAnimation(.linear(duration: 0.2)) {
                        animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
                    }
                    restartTickingTimer(intendedDuration: intendedDuration)
                }
            }
            return
        }

        // Recovery path: endDate exists but state isn't .running (background race).
        if let end = endDate {
            let remaining = max(0, Int(end.timeIntervalSinceNow))
            if remaining > 0 {
                state = .running
                timeRemaining = remaining
                withAnimation(.linear(duration: 0.2)) {
                    animatedProgress = 1 - (Double(timeRemaining) / Double(intendedDuration))
                }
                restartTickingTimer(intendedDuration: intendedDuration)
            } else {
                timer?.invalidate()
                timeRemaining = 0
                animatedProgress = 1
                handleTimerFinished()
            }
        }
    }
}


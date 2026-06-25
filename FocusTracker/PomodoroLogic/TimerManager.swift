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

    /// The absolute end date for the current running countdown.
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

        // Register with control center so deep links / intents can reach us
        TimerControlCenter.shared.register(self)

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
        let end = Date().addingTimeInterval(TimeInterval(focusDuration))
        await LiveActivityManager.shared.startLiveActivity(endDate: end, type: .focusTime, remainingSeconds: focusDuration)
    }
    
    func resumeTimer() {
        guard state == .paused else { return }
        startCountDown(resume: true)
        if let end = endDate {
            Task { await LiveActivityManager.shared.update(endDate: end, isPaused: false, remainingSeconds: timeRemaining) }
        }
    }
    
    private func startCountDown(resume: Bool = false) {
        state = .running
        
        let intendedDuration = currentDuration
        
        if !resume {
            timeRemaining = intendedDuration
            animatedProgress = 0
        }

        endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        if let end = endDate {
            scheduleNotification(for: end)
        }
        
        restartTickingTimer(intendedDuration: intendedDuration)
    }
    
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
    
    private func tick(intendedDuration: Int) {
        guard let end = endDate else {
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
        cancelScheduledNotification()
        playSystemSound()
        
        switch mode {
        case .focus:
            completeFocus()
            startBreakAutomatically()
        case .breakTime:
            completeBreak()
        }
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
        Task { await LiveActivityManager.shared.end() }
    }
    
    private func startBreakAutomatically() {
        mode = .breakTime
        state = .idle
        startCountDown()
        if let end = endDate {
            Task { await LiveActivityManager.shared.update(endDate: end, isPaused: false, type: .breakTime, remainingSeconds: timeRemaining) }
        }
    }

    func pauseTimer() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()

        if let end = endDate {
            timeRemaining = max(0, Int(end.timeIntervalSinceNow))
        }
        endDate = nil
        cancelScheduledNotification()
        Task { await LiveActivityManager.shared.update(endDate: nil, isPaused: true, remainingSeconds: timeRemaining) }
    }
    
    func resetTimer() {
        state = .idle
        timer?.invalidate()
        mode = .focus
        animatedProgress = 0
        timeRemaining = focusDuration
        endDate = nil
        cancelScheduledNotification()
        Task { await LiveActivityManager.shared.end() }
    }
    
    private var currentDuration: Int {
        if isUITesting { return 6 }
        return mode == .focus ? focusDuration : breakDuration
    }
    
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
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelScheduledNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [TimerManager.notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [TimerManager.notificationIdentifier])
    }

    // MARK: - App lifecycle handlers
    @objc private func appWillResignActive(_ notification: Notification) {
        timer?.invalidate()
    }

    @objc private func appDidBecomeActive(_ notification: Notification) {
        guard state == .running else { return }
        let intendedDuration = currentDuration
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
                Task { await LiveActivityManager.shared.update(endDate: end, isPaused: false, remainingSeconds: timeRemaining) }
            }
        }
    }
}

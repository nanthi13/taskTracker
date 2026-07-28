// Created by: nanthi13 on 27/07/2026

import Foundation

// Analytics helpers for arrays of PomodoroTaskModel.
extension Array where Element == PomodoroTaskModel {

    /// Total focus time in minutes across all tasks.
    /// Converts seconds to minutes using max(1, duration/60) to align with chart/list displays.
    func totalFocusMinutes() -> Int {
        reduce(0) { $0 + Swift.max(1, $1.duration / 60) }
    }

    /// Longest single session length in minutes.
    func longestSessionMinutes() -> Int {
        map { Swift.max(1, $0.duration / 60) }.max() ?? 0
    }

    /// Average session length in minutes (rounded to nearest minute).
    func averageSessionMinutes() -> Int {
        guard !isEmpty else { return 0 }
        let mins = map { Swift.max(1, $0.duration / 60) }
        let total = mins.reduce(0, +)
        return Int(round(Double(total) / Double(mins.count)))
    }

    // MARK: - Today-scoped metrics

    /// Filters to tasks whose date is today (by current Calendar).
    private func tasksForToday(calendar: Calendar = .current) -> [PomodoroTaskModel] {
        filter { calendar.isDateInToday($0.date) }
    }

    /// Longest session today, in minutes.
    func longestSessionTodayMinutes(calendar: Calendar = .current) -> Int {
        tasksForToday(calendar: calendar).map { Swift.max(1, $0.duration / 60) }.max() ?? 0
    }
    
    func amountOfSessionsToday(calendar: Calendar = .current) -> String {
        return String(tasksForToday(calendar: calendar).count)
    }

    /// Average session length today, in minutes (rounded).
    func averageSessionTodayMinutes(calendar: Calendar = .current) -> Int {
        let todays = tasksForToday(calendar: calendar).map { Swift.max(1, $0.duration / 60) }
        guard !todays.isEmpty else { return 0 }
        let total = todays.reduce(0, +)
        return Int(round(Double(total) / Double(todays.count)))
    }
}


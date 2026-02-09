//CREATED  BY: nanthi13 ON 05/02/2026

import Foundation

extension Array where Element == PomodoroTaskModel {
    func dailyTotals(calendar: Calendar = .current) -> [FocusAnalyticsPoint] {
        let grouped = Dictionary(grouping: self) {
            calendar.startOfDay(for: $0.date)
        }
        
        return grouped.map { date, tasks in
            FocusAnalyticsPoint(date: date, totalMinutes: tasks.reduce(0) {
                $0 + ($1.duration / 60)}
            )
        }
        .sorted { $0.date < $1.date}
    }
    
    func weeklyTotals(calendar: Calendar = .current) -> [FocusAnalyticsPoint] {
        let grouped = Dictionary(grouping: self) { task in
            calendar.dateInterval(of: .weekOfYear, for: task.date)?.start ?? task.date
        }
        
        return grouped.map { weekStart, tasks in
            FocusAnalyticsPoint(date: weekStart, totalMinutes: tasks.reduce(0)
                                { $0 + ($1.duration / 60) }
            )
        }
        .sorted { $0.date < $1.date}
    }
}


// Created by: nanthi13 on 15/07/2026

// ChartDataProvider.swift
import Foundation

/// Provides reusable calendar windowing and zero-fill logic for chart data.
enum ChartDataProvider {

    /// Returns the most recent data point's date if available; otherwise returns `Date()`.
    static func defaultAnchor(for data: [FocusAnalyticsPoint]) -> Date {
        data.last?.date ?? Date()
    }

    static func dailyWeekWindow(data: [FocusAnalyticsPoint], anchorDate: Date, page: Int) -> [FocusAnalyticsPoint] {
        let calendar = Calendar.current
        guard let targetRef = calendar.date(byAdding: .weekOfYear, value: -page, to: anchorDate),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetRef)
        else { return [] }

        let startOfWeek = calendar.startOfDay(for: weekInterval.start)
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek).map { calendar.startOfDay(for: $0) }
        }

        let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
            data.map { (calendar.startOfDay(for: $0.date), $0) }
        )

        return days.map { day in
            if let existing = index[day] {
                return existing
            } else {
                return FocusAnalyticsPoint(date: day, totalMinutes: 0)
            }
        }
    }

    static func weeklyMonthWindow(data: [FocusAnalyticsPoint], anchorDate: Date, page: Int) -> [FocusAnalyticsPoint] {
        let calendar = Calendar.current
        guard let targetRef = calendar.date(byAdding: .month, value: -page, to: anchorDate),
              let monthInterval = calendar.dateInterval(of: .month, for: targetRef)
        else { return [] }

        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end

        guard let firstWeekStartRaw = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
            return []
        }
        let firstWeekStart = calendar.startOfDay(for: firstWeekStartRaw)

        var weekStarts: [Date] = []
        var cursor = firstWeekStart
        while cursor < monthEnd {
            if cursor >= monthStart && cursor < monthEnd {
                weekStarts.append(calendar.startOfDay(for: cursor))
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
            cursor = next
        }

        let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
            data.map { point in
                let ws = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                let normalized = calendar.startOfDay(for: ws)
                return (normalized, FocusAnalyticsPoint(date: normalized, totalMinutes: point.totalMinutes))
            }
        )

        return weekStarts.map { ws in
            if let existing = index[ws] {
                return existing
            } else {
                return FocusAnalyticsPoint(date: ws, totalMinutes: 0)
            }
        }
    }

    static func maxDailyPages(data: [FocusAnalyticsPoint]) -> Int {
        let calendar = Calendar.current
        let weekStarts: [Date] = Array(Set(
            data.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start }
        )).sorted()
        return max(0, weekStarts.count - 1)
    }

    static func maxWeeklyPages(data: [FocusAnalyticsPoint]) -> Int {
        let calendar = Calendar.current
        let monthKeys: [Date] = Array(Set(
            data.compactMap { point in
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                let normalized = calendar.startOfDay(for: weekStart)
                return calendar.dateInterval(of: .month, for: normalized)?.start
            }
        )).sorted()
        return max(0, monthKeys.count - 1)
    }
}

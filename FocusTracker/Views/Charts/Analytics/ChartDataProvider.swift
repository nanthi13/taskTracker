// Created by: nanthi13 on 15/07/2026

// ChartDataProvider.swift
import Foundation

/// Provides reusable calendar windowing and zero-fill logic for chart data.
/// - Defaults keep existing behavior for callers.
/// - Week-based logic uses ISO 8601 internally by default for determinism (weeks start on Monday),
///   while still allowing calendar injection for tests or alternate policies.
enum ChartDataProvider {

    // MARK: - Public API (unchanged signatures)

    /// Returns the most recent data point's date if available; otherwise returns `Date()`.
    static func defaultAnchor(for data: [FocusAnalyticsPoint]) -> Date {
        data.last?.date ?? Date()
    }

    /// Daily window for the week containing `anchorDate - page*weeks`, normalized to 7 start-of-day dates, zero-filled.
    static func dailyWeekWindow(data: [FocusAnalyticsPoint], anchorDate: Date, page: Int) -> [FocusAnalyticsPoint] {
        dailyWeekWindow(data: data, anchorDate: anchorDate, page: page, dayCalendar: .current)
    }

    /// Weekly window for the month containing `anchorDate - page*months`, comprised of weeks whose start lies within that month, zero-filled.
    static func weeklyMonthWindow(data: [FocusAnalyticsPoint], anchorDate: Date, page: Int) -> [FocusAnalyticsPoint] {
        weeklyMonthWindow(
            data: data,
            anchorDate: anchorDate,
            page: page,
            weekCalendar: Calendar(identifier: .iso8601),
            monthCalendar: .current
        )
    }

    /// Maximum pages for daily (weeks): counts distinct week starts minus one.
    static func maxDailyPages(data: [FocusAnalyticsPoint]) -> Int {
        maxDailyPages(data: data, weekCalendar: Calendar(identifier: .iso8601))
    }

    /// Maximum pages for weekly (months): counts distinct month starts minus one.
    static func maxWeeklyPages(data: [FocusAnalyticsPoint]) -> Int {
        maxWeeklyPages(
            data: data,
            weekCalendar: Calendar(identifier: .iso8601),
            monthCalendar: .current
        )
    }

    // MARK: - Injected-calendar overloads (internal)

    /// Calendar-injectable variant for daily windowing.
    static func dailyWeekWindow(
        data: [FocusAnalyticsPoint],
        anchorDate: Date,
        page: Int,
        dayCalendar: Calendar
    ) -> [FocusAnalyticsPoint] {
        let cal = dayCalendar
        guard let targetRef = cal.date(byAdding: .weekOfYear, value: -page, to: anchorDate),
              let weekInterval = cal.dateInterval(of: .weekOfYear, for: targetRef)
        else { return [] }

        let startOfWeek = cal.startOfDay(for: weekInterval.start)
        let days: [Date] = (0..<7).compactMap {
            cal.date(byAdding: .day, value: $0, to: startOfWeek).map { startOfDay($0, in: cal) }
        }

        // Index points by normalized start-of-day for fast lookup.
        let index: [Date: FocusAnalyticsPoint] = Dictionary(
            uniqueKeysWithValues: data.map { (startOfDay($0.date, in: cal), $0) }
        )

        return days.map { day in
            if let existing = index[day] {
                return existing
            } else {
                return FocusAnalyticsPoint(date: day, totalMinutes: 0)
            }
        }
    }

    /// Calendar-injectable variant for weekly windowing (weeks-in-month).
    /// - weekCalendar: used for week alignment and week starts (default ISO 8601).
    /// - monthCalendar: used for month boundaries (default current).
    static func weeklyMonthWindow(
        data: [FocusAnalyticsPoint],
        anchorDate: Date,
        page: Int,
        weekCalendar: Calendar,
        monthCalendar: Calendar
    ) -> [FocusAnalyticsPoint] {
        let wcal = weekCalendar
        let mcal = monthCalendar

        guard let targetRef = mcal.date(byAdding: .month, value: -page, to: anchorDate),
              let monthInterval = mcal.dateInterval(of: .month, for: targetRef)
        else { return [] }

        // Build list of week starts whose start lies within the month interval (existing behavior).
        let weekStarts = weekStartsWhoseStartIsInside(monthInterval: monthInterval, weekCalendar: wcal)

        // Index data by normalized week start.
        let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
            data.map { point in
                let ws = wcal.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                let normalized = startOfDay(ws, in: wcal)
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

    /// Calendar-injectable variant for daily max pages (weeks).
    static func maxDailyPages(data: [FocusAnalyticsPoint], weekCalendar: Calendar) -> Int {
        let wcal = weekCalendar
        let weekStarts: [Date] = Array(Set(
            data.compactMap { wcal.dateInterval(of: .weekOfYear, for: $0.date)?.start }
        )).sorted()
        return max(0, weekStarts.count - 1)
    }

    /// Calendar-injectable variant for weekly max pages (months).
    static func maxWeeklyPages(data: [FocusAnalyticsPoint], weekCalendar: Calendar, monthCalendar: Calendar) -> Int {
        let wcal = weekCalendar
        let mcal = monthCalendar
        let monthKeys: [Date] = Array(Set(
            data.compactMap { point in
                let weekStart = wcal.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                let normalized = startOfDay(weekStart, in: wcal)
                return mcal.dateInterval(of: .month, for: normalized)?.start
            }
        )).sorted()
        return max(0, monthKeys.count - 1)
    }

    // MARK: - Private helpers

    /// Normalizes a date to the start of the day in the given calendar.
    private static func startOfDay(_ date: Date, in cal: Calendar) -> Date {
        cal.startOfDay(for: date)
    }

    /// Produces week starts whose start lies inside the provided month interval (inclusive of start, exclusive of end).
    /// This matches the existing behavior of weeklyMonthWindow.
    private static func weekStartsWhoseStartIsInside(monthInterval: DateInterval, weekCalendar: Calendar) -> [Date] {
        let wcal = weekCalendar
        // Start from the week containing the month start.
        guard let firstWeekStartRaw = wcal.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start else {
            return []
        }
        var weekStarts: [Date] = []
        var cursor = firstWeekStartRaw

        while cursor < monthInterval.end {
            // Only include weeks whose start lies within the month interval.
            if cursor >= monthInterval.start && cursor < monthInterval.end {
                weekStarts.append(startOfDay(cursor, in: wcal))
            }
            guard let next = wcal.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
            cursor = next
        }
        return weekStarts
    }
}


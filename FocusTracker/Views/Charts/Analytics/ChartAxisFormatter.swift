// ChartAxisFormatter.swift
import Foundation
import SwiftUI

/// Centralized axis and range label formatting for charts.
/// Notes:
/// - Daily x-axis uses fixed English single-letter weekday initials: S M T W T F S (Sun..Sat).
/// - Weekly x-axis uses ISO 8601 week numbers (weeks start on Monday).
enum ChartAxisFormatter {

    // Fixed English weekday initials (Sun..Sat).
    private static let englishWeekdayInitials: [String] = ["S", "M", "T", "W", "T", "F", "S"]

    // Internal calendars for consistency. ISO is used for week numbering.
    private static let systemCalendar: Calendar = .current
    private static let isoCalendar: Calendar = Calendar(identifier: .iso8601)

    static func xAxisLabel(for date: Date, granularity: ChartGranularity, compact: Bool) -> Text {
        switch granularity {
        case .daily:
            // Always show single-letter weekday initials: S M T W T F S (Sun=1 ... Sat=7)
            let cal = systemCalendar
            let weekday = cal.component(.weekday, from: date)
            let index = max(1, min(7, weekday)) - 1
            return Text(englishWeekdayInitials[index])

        case .weekly:
            // Display ISO week numbers as x-axis labels (weeks start Monday).
            let week = isoCalendar.component(.weekOfYear, from: date)
            if compact {
                // Compact card: short "W5" style
                return Text("W\(week)")
            } else {
                // Detail view: more descriptive "Week \(week)"
                return Text("Week \(week)")
            }
        }
    }

    static func rangeLabel(start: Date, end: Date, granularity: ChartGranularity) -> String {
        // Keep visible output identical while normalizing via the system calendar
        // (no change to behavior, just centralizing calendar usage).
        let startLabel = start.formatted(.dateTime.month().day())
        let endLabel = end.formatted(.dateTime.month().day())
        switch granularity {
        case .daily:
            return "\(startLabel) - \(endLabel)"
        case .weekly:
            // Keep the existing month/day span for the visible month window.
            return "Weeks: \(startLabel) - \(endLabel)"
        }
    }
}


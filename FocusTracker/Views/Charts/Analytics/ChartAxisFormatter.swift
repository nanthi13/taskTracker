// ChartAxisFormatter.swift
import Foundation
import SwiftUI

/// Centralized axis and range label formatting for charts.
enum ChartAxisFormatter {

    static func xAxisLabel(for date: Date, granularity: ChartGranularity, compact: Bool) -> Text {
        switch granularity {
        case .daily:
            // Always show single-letter weekday initials: M T W T F S S
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: date) // 1=Sun ... 7=Sat
            // Map to fixed English initials as requested.
            // Order: Sun, Mon, Tue, Wed, Thu, Fri, Sat
            let map = ["S", "M", "T", "W", "T", "F", "S"]
            let index = max(1, min(7, weekday)) - 1
            return Text(map[index])

        case .weekly:
            // Display ISO week numbers as x-axis labels.
            // Use ISO 8601 calendar so week numbers match common expectations (weeks start on Monday).
            let iso = Calendar(identifier: .iso8601)
            let week = iso.component(.weekOfYear, from: date)
            if compact {
                // Compact card: short "W5" style
                return Text("W\(week)")
            } else {
                // Detail view: more descriptive "Week 5"
                return Text("Week \(week)")
            }
        }
    }

    static func rangeLabel(start: Date, end: Date, granularity: ChartGranularity) -> String {
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

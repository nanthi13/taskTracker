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
            if compact {
                return Text(date, format: .dateTime.month().day())
            } else {
                return Text("Week of \(date.formatted(.dateTime.month().day()))")
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
            return "Weeks: \(startLabel) - \(endLabel)"
        }
    }
}

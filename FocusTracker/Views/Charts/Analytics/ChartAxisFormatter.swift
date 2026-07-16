// ChartAxisFormatter.swift
import Foundation
import SwiftUI

/// Centralized axis and range label formatting for charts.
enum ChartAxisFormatter {

    static func xAxisLabel(for date: Date, granularity: ChartGranularity, compact: Bool) -> Text {
        switch granularity {
        case .daily:
            if compact {
                return Text(date, format: .dateTime.weekday(.abbreviated))
            } else {
                return Text(date.formatted(.dateTime.weekday(.wide).month().day()))
            }
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

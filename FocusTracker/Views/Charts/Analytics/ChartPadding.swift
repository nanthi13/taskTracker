// ChartPadding.swift
import Foundation

enum ChartPadding {
    static func paddedDomain(for granularity: ChartGranularity, first: Date, last: Date, calendar: Calendar = .current) -> ClosedRange<Date> {
        switch granularity {
        case .daily:
            let start = calendar.date(byAdding: .hour, value: -10, to: first) ?? first
            let end = calendar.date(byAdding: .hour, value: 10, to: last) ?? last
            return start...end
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -3, to: first) ?? first
            let end = calendar.date(byAdding: .day, value: 3, to: last) ?? last
            return start...end
        }
    }
}

// Created by: nanthi13 on 05/02/2026

import Foundation

/// Aggregated focus total for a given date bucket (day or week).
struct FocusAnalyticsPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let totalMinutes: Int

    static func == (lhs: FocusAnalyticsPoint, rhs: FocusAnalyticsPoint) -> Bool {
        lhs.date == rhs.date && lhs.totalMinutes == rhs.totalMinutes
    }
}

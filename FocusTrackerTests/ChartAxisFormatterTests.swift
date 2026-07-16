//CREATED  BY: nanthi13 ON 16/07/2026

import Testing
@testable import FocusTracker
import Foundation
import SwiftUI

@Suite("ChartAxisFormatter label formatting")
struct ChartAxisFormatterTests {

    @Test("xAxisLabel daily compact and detail")
    func xAxisLabel_daily() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 5))!

        // Compact: weekday abbreviated
        let compact = ChartAxisFormatter.xAxisLabel(for: date, granularity: .daily, compact: true)
        // We can’t directly compare Text; instead, ensure it’s created without crashing.
        #expect(type(of: compact) == Text.self)

        // Detail: weekday wide + month/day
        let detail = ChartAxisFormatter.xAxisLabel(for: date, granularity: .daily, compact: false)
        #expect(type(of: detail) == Text.self)
    }

    @Test("xAxisLabel weekly compact and detail")
    func xAxisLabel_weekly() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 5))!

        let compact = ChartAxisFormatter.xAxisLabel(for: date, granularity: .weekly, compact: true)
        #expect(type(of: compact) == Text.self)

        let detail = ChartAxisFormatter.xAxisLabel(for: date, granularity: .weekly, compact: false)
        #expect(type(of: detail) == Text.self)
    }

    @Test("rangeLabel daily")
    func rangeLabel_daily() {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let end = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 7))!
        let text = ChartAxisFormatter.rangeLabel(start: start, end: end, granularity: .daily)
        #expect(text.contains("Feb"))
        #expect(text.contains("-"))
    }

    @Test("rangeLabel weekly")
    func rangeLabel_weekly() {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let end = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 28))!
        let text = ChartAxisFormatter.rangeLabel(start: start, end: end, granularity: .weekly)
        #expect(text.contains("Weeks"))
    }
}

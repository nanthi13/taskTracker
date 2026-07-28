//CREATED  BY: nanthi13 ON 16/07/2026

import Testing
@testable import FocusTracker
import Foundation

@Suite("ChartDataProvider windowing and zero-fill")
struct ChartDataProviderTests {

    // Use fixed calendars for determinism across locales/regions.
    private let greg = Calendar(identifier: .gregorian)
    private let iso = Calendar(identifier: .iso8601)

    private func makePoint(_ y: Int, _ m: Int, _ d: Int, minutes: Int) -> FocusAnalyticsPoint {
        let date = greg.date(from: DateComponents(year: y, month: m, day: d))!
        return FocusAnalyticsPoint(date: date, totalMinutes: minutes)
    }

    // Helper for building deterministic dates.
    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        greg.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test("dailyWeekWindow builds 7 days and zero-fills missing")
    func daily_buildsWeekAndZeroFills() {
        // Data on Mon (3), Wed (5), Sun (9) of the same week.
        // Week containing 2026-02-05 (Thu).
        let data: [FocusAnalyticsPoint] = [
            makePoint(2026, 2, 3, minutes: 30),
            makePoint(2026, 2, 5, minutes: 60),
            makePoint(2026, 2, 9, minutes: 15)
        ]

        let anchor = makeDate(2026, 2, 5) // Thu
        let window = ChartDataProvider.dailyWeekWindow(data: data, anchorDate: anchor, page: 0)

        #expect(window.count == 7)

        // Ensure the week starts on the system's weekOfYear start using ISO for determinism.
        let weekInterval = iso.dateInterval(of: .weekOfYear, for: anchor)!
        let startOfWeek = iso.startOfDay(for: weekInterval.start)
        #expect(iso.isDate(window.first!.date, inSameDayAs: startOfWeek))

        // Check zero-fill on a day with no data.
        // We know we only added Mon, Wed, Sun; so Tue/Thu/Fri/Sat should be 0 except Wed/Sun.
        if let anyMissing = window.first(where: { !iso.isDate($0.date, inSameDayAs: makeDate(2026, 2, 3)) &&
                                                  !iso.isDate($0.date, inSameDayAs: makeDate(2026, 2, 5)) &&
                                                  !iso.isDate($0.date, inSameDayAs: makeDate(2026, 2, 9)) }) {
            #expect(anyMissing.totalMinutes == 0)
        }
    }

    @Test("maxDailyPages counts distinct weeks minus one")
    func daily_maxPages() {
        // Two weeks, one point each week.
        let d1 = makeDate(2026, 2, 3)
        let d2 = makeDate(2026, 2, 12)
        let data = [
            FocusAnalyticsPoint(date: d1, totalMinutes: 10),
            FocusAnalyticsPoint(date: d2, totalMinutes: 20)
        ]
        let pages = ChartDataProvider.maxDailyPages(data: data)
        // Two distinct weeks => maxPage = 1
        #expect(pages == 1)
    }

    @Test("weeklyMonthWindow returns weeks in month and zero-fills")
    func weekly_buildsWeeksInMonth() {
        // Points on first and third weeks of Feb 2026.
        let p1 = makePoint(2026, 2, 3, minutes: 40)
        let p3 = makePoint(2026, 2, 17, minutes: 80)
        let data = [p1, p3]

        let anchor = makeDate(2026, 2, 20)
        let window = ChartDataProvider.weeklyMonthWindow(data: data, anchorDate: anchor, page: 0)

        // Expect at least 4 weeks in most months; exact count depends on calendar boundaries.
        #expect(window.count >= 4)

        // All points should have dates within Feb 2026 by month-of containing week start.
        for pt in window {
            let month = greg.component(.month, from: pt.date)
            #expect(month == 2)
        }

        // Ensure zero-fill exists (some week totalMinutes == 0).
        let zeroExists = window.contains(where: { $0.totalMinutes == 0 })
        #expect(zeroExists)
    }

    @Test("maxWeeklyPages counts distinct months minus one")
    func weekly_maxPages() {
        let jan = makeDate(2026, 1, 24)
        let feb = makeDate(2026, 2, 5)
        let data = [
            FocusAnalyticsPoint(date: jan, totalMinutes: 10),
            FocusAnalyticsPoint(date: feb, totalMinutes: 20)
        ]
        let pages = ChartDataProvider.maxWeeklyPages(data: data)
        #expect(pages == 1)
    }
}


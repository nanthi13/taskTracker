//CREATED  BY: nanthi13 ON 16/07/2026

import Testing
@testable import FocusTracker
import Foundation

@Suite("ChartDataProvider windowing and zero-fill")
struct ChartDataProviderTests {

    private func makePoint(_ y: Int, _ m: Int, _ d: Int, minutes: Int) -> FocusAnalyticsPoint {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: m, day: d))!
        return FocusAnalyticsPoint(date: date, totalMinutes: minutes)
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

        let anchor = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 5))! // Thu
        let window = ChartDataProvider.dailyWeekWindow(data: data, anchorDate: anchor, page: 0)

        #expect(window.count == 7)

        // Ensure the week starts on the system's weekOfYear start.
        let cal = Calendar.current
        let weekInterval = cal.dateInterval(of: .weekOfYear, for: anchor)!
        let startOfWeek = cal.startOfDay(for: weekInterval.start)
        #expect(cal.isDate(window.first!.date, inSameDayAs: startOfWeek))

        // Check zero-fill on a day with no data (e.g., Tuesday if present).
        let tuesday = cal.date(byAdding: .day, value: 1, to: startOfWeek)!
        let tuesdayPoint = window.first(where: { cal.isDate($0.date, inSameDayAs: tuesday) })
        #expect(tuesdayPoint != nil)
        // Depending on your locale/firstWeekday, pick a day you know is missing.
        // We know we only added Mon, Wed, Sun; so Tue/Thu/Fri/Sat should be 0 except Wed/Sun.
        // Verify one of them:
        if let anyMissing = window.first(where: { !cal.isDate($0.date, inSameDayAs: makeDate(2026, 2, 3)) &&
                                                  !cal.isDate($0.date, inSameDayAs: makeDate(2026, 2, 5)) &&
                                                  !cal.isDate($0.date, inSameDayAs: makeDate(2026, 2, 9)) }) {
            #expect(anyMissing.totalMinutes == 0)
        }
    }

    @Test("maxDailyPages counts distinct weeks minus one")
    func daily_maxPages() {
        let cal = Calendar.current
        // Two weeks, one point each week.
        let d1 = cal.date(from: DateComponents(year: 2026, month: 2, day: 3))!
        let d2 = cal.date(from: DateComponents(year: 2026, month: 2, day: 12))!
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

        // All points should have week-start-aligned dates within Feb 2026.
        let cal = Calendar.current
        for pt in window {
            let month = cal.component(.month, from: pt.date)
            #expect(month == 2)
        }

        // Ensure zero-fill exists (some week totalMinutes == 0).
        let zeroExists = window.contains(where: { $0.totalMinutes == 0 })
        #expect(zeroExists)
    }

    @Test("maxWeeklyPages counts distinct months minus one")
    func weekly_maxPages() {
        let cal = Calendar.current
        let jan = cal.date(from: DateComponents(year: 2026, month: 1, day: 24))!
        let feb = cal.date(from: DateComponents(year: 2026, month: 2, day: 5))!
        let data = [
            FocusAnalyticsPoint(date: jan, totalMinutes: 10),
            FocusAnalyticsPoint(date: feb, totalMinutes: 20)
        ]
        let pages = ChartDataProvider.maxWeeklyPages(data: data)
        #expect(pages == 1)
    }

    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

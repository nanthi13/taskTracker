// Created by: nanthi13 on 05/02/2026

import SwiftUI
import Charts

/// Compact chart card showing either daily or weekly focus totals.
/// - Animates in data on appear
/// - Tapping the card invokes onTap (typically navigates to detail)
struct FocusChartCard: View {
    let title: String
    let data: [FocusAnalyticsPoint]
    let granularity: ChartGranularity
    let onTap: () -> Void

    @State private var animatedData: [FocusAnalyticsPoint] = []

    // Compute a windowed set of points:
    // - daily: exactly the current (most recent) calendar week (7 days), zero-filled
    // - weekly: only the weeks within the current (most recent) calendar month, zero-filled
    private var visibleData: [FocusAnalyticsPoint] {
        let calendar = Calendar.current

        switch granularity {
        case .daily:
            // Reference is the latest data date or today
            let ref = data.last?.date ?? Date()
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: ref) else {
                return []
            }
            let startOfWeek = calendar.startOfDay(for: weekInterval.start)
            // Build 7 days for the week
            let days: [Date] = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: startOfWeek).map { calendar.startOfDay(for: $0) }
            }
            // Index by startOfDay
            let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
                data.map { (calendar.startOfDay(for: $0.date), $0) }
            )
            // Fill missing days with zeros
            return days.map { day in
                if let existing = index[day] {
                    return existing
                } else {
                    return FocusAnalyticsPoint(date: day, totalMinutes: 0)
                }
            }

        case .weekly:
            // Reference is the latest data date or today
            let ref = data.last?.date ?? Date()
            guard let monthInterval = calendar.dateInterval(of: .month, for: ref) else {
                return []
            }
            let monthStart = monthInterval.start
            let monthEnd = monthInterval.end

            // Find the first week boundary that intersects the month start
            guard let firstWeekStartRaw = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
                return []
            }
            let firstWeekStart = calendar.startOfDay(for: firstWeekStartRaw)

            // Build consecutive week starts, filter to those strictly within the month interval
            var weekStarts: [Date] = []
            var cursor = firstWeekStart
            while cursor < monthEnd {
                if cursor >= monthStart && cursor < monthEnd {
                    weekStarts.append(calendar.startOfDay(for: cursor))
                }
                guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
                cursor = next
            }

            // Index incoming weekly points by their normalized week start
            let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
                data.map { point in
                    let ws = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                    let normalized = calendar.startOfDay(for: ws)
                    return (normalized, FocusAnalyticsPoint(date: normalized, totalMinutes: point.totalMinutes))
                }
            )

            // Fill missing weeks within the month with zero totals and keep order by week start
            let monthPoints: [FocusAnalyticsPoint] = weekStarts.map { ws in
                if let existing = index[ws] {
                    return existing
                } else {
                    return FocusAnalyticsPoint(date: ws, totalMinutes: 0)
                }
            }

            return monthPoints
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Chart(animatedData) { point in
                // Card uses compact marks; selection is handled in detail view only.
                FocusChartMarks.build(point: point, granularity: granularity, selectedDate: nil, isCompact: true)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            switch granularity {
                            case .daily:
                                Text(date, format: .dateTime.weekday(.abbreviated))
                            case .weekly:
                                // Show week start day within the month
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 110)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { onTap() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedData = visibleData
            }
        }
        .onChange(of: data) {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedData = visibleData
            }
        }
        .onChange(of: granularity) {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedData = visibleData
            }
        }
    }
}

// Note: FocusChartMarks and ChartGranularity are expected to be defined elsewhere.
// Ensure their APIs remain stable for reuse across card and detail chart views.

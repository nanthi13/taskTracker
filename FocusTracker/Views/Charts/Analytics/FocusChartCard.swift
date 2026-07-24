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

    // Compute a windowed set of points via shared provider:
    // - daily: exactly the current (most recent) calendar week (7 days), zero-filled
    // - weekly: only the weeks within the current (most recent) calendar month, zero-filled
    private var visibleData: [FocusAnalyticsPoint] {
        let anchor = ChartDataProvider.defaultAnchor(for: data)
        switch granularity {
        case .daily:
            return ChartDataProvider.dailyWeekWindow(data: data, anchorDate: anchor, page: 0)
        case .weekly:
            return ChartDataProvider.weeklyMonthWindow(data: data, anchorDate: anchor, page: 0)
        }
    }

    // Modest padding around the x-domain so first/last labels aren’t clipped,
    // but small enough to avoid shrinking the plot area.
    // TODO: refactor reused code multiple times
    private var paddedDomain: ClosedRange<Date>? {
        guard let first = animatedData.first?.date, let last = animatedData.last?.date else { return nil }
        let cal = Calendar.current
        switch granularity {
        case .daily:
            // ±8–10 hours is usually enough to pull ticks off the edges
            let start = cal.date(byAdding: .hour, value: -8, to: first) ?? first
            let end = cal.date(byAdding: .hour, value: 8, to: last) ?? last
            return start...end
        case .weekly:
            // ±2 days is sufficient for week-start ticks
            let start = cal.date(byAdding: .day, value: -2, to: first) ?? first
            let end = cal.date(byAdding: .day, value: 2, to: last) ?? last
            return start...end
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
            // Slight domain pad so ticks aren’t at edges.
            .chartXScale(domain: paddedDomain ?? (animatedData.first?.date ?? Date())...(animatedData.last?.date ?? Date()))
            // Add plot padding so axis labels have room without reducing the plot width too much.
            .chartPlotStyle { plotArea in
                plotArea
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
            }
            .chartXAxis {
                // Force all ticks to match our visible dates to avoid pruning (e.g., M W F only).
                AxisMarks(values: animatedData.map { $0.date }) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            ChartAxisFormatter.xAxisLabel(for: date, granularity: granularity, compact: true)
                                .font(.caption2)
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

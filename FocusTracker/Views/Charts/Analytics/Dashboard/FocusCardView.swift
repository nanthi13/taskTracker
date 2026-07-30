// Created by: nanthi13 on 29/07/2026

import SwiftUI
import Charts

/// Unified compact chart card used for analytics dashboard.
/// Supports three modes:
/// - dailyTotals: aggregated last week (7 days) window
/// - weeklyTotals: aggregated weeks within current month window
/// - todaySessions: per-session bars for today
///
/// Tapping the card invokes onTap so the caller can navigate to the appropriate detail.
struct FocusCardView: View {

    enum Mode: Equatable {
        case dailyTotals([FocusAnalyticsPoint])
        case weeklyTotals([FocusAnalyticsPoint])
        case todaySessions([PomodoroTaskModel])
    }

    let title: String
    let mode: Mode
    let onTap: () -> Void

    @State private var animatedAnalytics: [FocusAnalyticsPoint] = []
    @State private var animatedSessions: [SessionPoint] = []

    // Visible data for aggregated modes (windowed + zero-filled)
    private var visibleAnalyticsData: [FocusAnalyticsPoint] {
        switch mode {
        case .dailyTotals(let data):
            let anchor = ChartDataProvider.defaultAnchor(for: data)
            return ChartDataProvider.dailyWeekWindow(data: data, anchorDate: anchor, page: 0)
        case .weeklyTotals(let data):
            let anchor = ChartDataProvider.defaultAnchor(for: data)
            return ChartDataProvider.weeklyMonthWindow(data: data, anchorDate: anchor, page: 0)
        case .todaySessions:
            return []
        }
    }

    private var granularity: ChartGranularity? {
        switch mode {
        case .dailyTotals: return .daily
        case .weeklyTotals: return .weekly
        case .todaySessions: return nil
        }
    }

    private var todaySessionPoints: [SessionPoint] {
        switch mode {
        case .todaySessions(let tasks):
            let cal = Calendar.current
            let todays = tasks.filter { cal.isDateInToday($0.date) }
            return todays
                .sorted(by: { $0.date < $1.date })
                .map { SessionPoint(start: $0.date, minutes: max(1, $0.duration / 60)) }
        default:
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            switch mode {
            case .dailyTotals, .weeklyTotals:
                Chart(animatedAnalytics, id: \.date) { point in
                    FocusChartMarks.build(
                        point: point,
                        granularity: granularity ?? .daily,
                        selectedDate: nil,
                        isCompact: true
                    )
                }
                .chartXScale(
                    domain: {
                        if let first = animatedAnalytics.first?.date, let last = animatedAnalytics.last?.date,
                           let g = granularity {
                            return ChartPadding.paddedDomain(for: g, first: first, last: last)
                        } else {
                            let now = Date()
                            return now...now
                        }
                    }()
                )
                .chartPlotStyle { plotArea in
                    plotArea
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                }
                .chartXAxis {
                    AxisMarks(values: animatedAnalytics.map { $0.date }) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self), let g = granularity {
                                ChartAxisFormatter.xAxisLabel(for: date, granularity: g, compact: true)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 110)

            case .todaySessions:
                if animatedSessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions today",
                        systemImage: "calendar",
                        description: Text("Start a focus session to see it here.")
                    )
                    .frame(height: 110)
                } else {
                    Chart(animatedSessions) { session in
                        BarMark(
                            x: .value("Start", session.start),
                            y: .value("Minutes", session.minutes)
                        )
                        .cornerRadius(3)
                        .foregroundStyle(Color.accentColor.opacity(0.85))
                        .annotation(position: .top) {
                            Text("\(session.minutes)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                                }
                            }
                        }
                    }
                    .chartYAxis(.hidden)
                    .frame(height: 110)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { onTap() }
        .onAppear {
            switch mode {
            case .dailyTotals, .weeklyTotals:
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedAnalytics = visibleAnalyticsData
                }
            case .todaySessions:
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedSessions = todaySessionPoints
                }
            }
        }
        .onChange(of: mode, initial: false) { _, newValue in
            switch newValue {
            case .dailyTotals, .weeklyTotals:
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedAnalytics = visibleAnalyticsData
                }
            case .todaySessions:
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedSessions = todaySessionPoints
                }
            }
        }
    }
}

// Lightweight data for the daily sessions chart.
private struct SessionPoint: Identifiable, Equatable {
    let id = UUID()
    let start: Date
    let minutes: Int
}


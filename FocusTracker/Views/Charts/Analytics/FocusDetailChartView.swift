// Created by: nanthi13 on 06/02/2026

import Foundation
import SwiftUI
import Charts

/// Detail chart view with paging windows and point selection:
/// - Pages through windows (daily: 7 days, weekly: month-by-month) using buttons or horizontal swipes.
/// - Shows an average RuleMark for the visible window.
/// - Selecting a data point maps to the most recent task in that period and presents a detail sheet.
struct FocusDetailChartView: View {
    let title: String
    let data: [FocusAnalyticsPoint]
    let granularity: ChartGranularity
    let tasks: [PomodoroTaskModel]

    /// Optional anchor for the initial visible window.
    /// - For .daily: week-of-year containing this date is used for page 0.
    /// - For .weekly: ignored (month-based paging remains anchored to most recent).
    let anchorDate: Date?

    @State private var selectedPoint: FocusAnalyticsPoint?
    @State private var selectedTask: PomodoroTaskModel?

    /// 0 = most recent window (current week or current month), 1 = previous window, etc.
    @State private var page: Int = 0

    /// Visible slice for the current page (delegated to ChartDataProvider).
    private var visibleData: [FocusAnalyticsPoint] {
        switch granularity {
        case .daily:
            let anchor = anchorDate ?? ChartDataProvider.defaultAnchor(for: data)
            return ChartDataProvider.dailyWeekWindow(
                data: data,
                anchorDate: anchor,
                page: page
            )
        case .weekly:
            let anchor = ChartDataProvider.defaultAnchor(for: data)
            return ChartDataProvider.weeklyMonthWindow(
                data: data,
                anchorDate: anchor,
                page: page
            )
        }
    }

    /// Average minutes over the visible window.
    private var averageMinutes: Double? {
        guard !visibleData.isEmpty else { return nil }
        let sum = visibleData.reduce(0.0) { $0 + Double($1.totalMinutes) }
        return sum / Double(visibleData.count)
    }

    /// Maximum available page index.
    private var maxPage: Int {
        switch granularity {
        case .daily:
            return ChartDataProvider.maxDailyPages(data: data)
        case .weekly:
            return ChartDataProvider.maxWeeklyPages(data: data)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with range and pager controls.
            HStack(spacing: 12) {
                Text(title).font(.headline)
                Spacer()
                if let first = visibleData.first?.date, let last = visibleData.last?.date {
                    Text(ChartAxisFormatter.rangeLabel(start: first, end: last, granularity: granularity))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            page = min(page + 1, maxPage)
                            selectedPoint = nil
                            selectedTask = nil
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .disabled(page >= maxPage)

                    Button {
                        withAnimation {
                            page = max(page - 1, 0)
                            selectedPoint = nil
                            selectedTask = nil
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .disabled(page == 0)
                }
            }
            .padding(.horizontal)

            // Selected value readout.
            if let selectedPoint {
                HStack {
                    ChartAxisFormatter.xAxisLabel(for: selectedPoint.date, granularity: granularity, compact: false)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(selectedPoint.totalMinutes) min")
                        .font(.headline)
                }
                .padding(.horizontal)
            }

            Chart {
                ForEach(visibleData, id: \.date) { point in
                    FocusChartMarks.build(
                        point: point,
                        granularity: granularity,
                        selectedDate: selectedPoint?.date,
                        isCompact: false
                    )
                }
                if let avg = averageMinutes {
                    RuleMark(y: .value("Average", avg))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundStyle(Color.accentColor.gradient)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("\(Int(round(avg))) min avg")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                        }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            ChartAxisFormatter.xAxisLabel(for: date, granularity: granularity, compact: false)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            // Swipe to page windows.
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        let translation = value.translation
                        let predicted = value.predictedEndTranslation
                        let threshold: CGFloat = 40
                        if translation.width < -threshold || predicted.width < -threshold {
                            withAnimation {
                                page = min(page + 1, maxPage)
                                selectedPoint = nil
                                selectedTask = nil
                            }
                        } else if translation.width > threshold || predicted.width > threshold {
                            withAnimation {
                                page = max(page - 1, 0)
                                selectedPoint = nil
                                selectedTask = nil
                            }
                        }
                    }
            )
            // Tap/drag selection overlay; also supports swipe paging.
            .chartOverlay { proxy in
                GeometryReader { _ in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x) {
                                        selectedPoint = closestPointInVisible(to: date)
                                        if let selected = selectedPoint {
                                            selectedTask = taskFor(analyticsPoint: selected)
                                        } else {
                                            selectedTask = nil
                                        }
                                    }
                                }
                                .onEnded { value in
                                    let translation = value.translation
                                    let predicted = value.predictedEndTranslation
                                    let threshold: CGFloat = 40
                                    if translation.width < -threshold || predicted.width < -threshold {
                                        withAnimation {
                                            page = min(page + 1, maxPage)
                                            selectedPoint = nil
                                            selectedTask = nil
                                        }
                                    } else if translation.width > threshold || predicted.width > threshold {
                                        withAnimation {
                                            page = max(page - 1, 0)
                                            selectedPoint = nil
                                            selectedTask = nil
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 320)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        // Presents TaskDetailView when a concrete task is selected.
        .taskDetailSheet(selectedTask: $selectedTask)
    }

    // MARK: - Helpers

    private func closestPointInVisible(to date: Date) -> FocusAnalyticsPoint? {
        visibleData.min {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }
    }

    /// Maps an analytics point to the most recent task in that period.
    private func taskFor(analyticsPoint: FocusAnalyticsPoint) -> PomodoroTaskModel? {
        let calendar = Calendar.current
        switch granularity {
        case .daily:
            let candidates = tasks.filter { calendar.isDate($0.date, inSameDayAs: analyticsPoint.date) }
            return candidates.max(by: { $0.date < $1.date })
        case .weekly:
            let candidates = tasks.filter {
                let start = calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start ?? $0.date
                return Calendar.current.isDate(start, inSameDayAs: analyticsPoint.date)
            }
            return candidates.max(by: { $0.date < $1.date })
        }
    }
}

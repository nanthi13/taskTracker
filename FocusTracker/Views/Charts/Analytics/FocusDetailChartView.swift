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

    @State private var selectedPoint: FocusAnalyticsPoint?
    @State private var selectedTask: PomodoroTaskModel?

    /// 0 = most recent window (current week or current month), 1 = previous window, etc.
    @State private var page: Int = 0

    private var windowSize: Int {
        switch granularity {
        case .daily: return 7
        case .weekly: return 0 // unused with month-based paging
        }
    }

    /// Visible slice for the current page.
    private var visibleData: [FocusAnalyticsPoint] {
        switch granularity {
        case .weekly:
            // Month-based paging: page 0 = current month, page 1 = previous month, etc.
            let calendar = Calendar.current

            // Choose a reference date: latest data date or today.
            let latestDate = data.last?.date ?? Date()

            // Shift by `page` months into the past to determine the target month.
            guard let targetRef = calendar.date(byAdding: .month, value: -page, to: latestDate),
                  let monthInterval = calendar.dateInterval(of: .month, for: targetRef)
            else { return [] }

            let monthStart = monthInterval.start
            let monthEnd = monthInterval.end

            // Build week starts that fall within the month interval.
            guard let firstWeekStartRaw = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
                return []
            }
            let firstWeekStart = calendar.startOfDay(for: firstWeekStartRaw)

            var weekStarts: [Date] = []
            var cursor = firstWeekStart
            while cursor < monthEnd {
                if cursor >= monthStart && cursor < monthEnd {
                    weekStarts.append(calendar.startOfDay(for: cursor))
                }
                guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
                cursor = next
            }

            // Index incoming weekly data by normalized week start.
            let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
                data.map { point in
                    let ws = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                    let normalized = calendar.startOfDay(for: ws)
                    return (normalized, FocusAnalyticsPoint(date: normalized, totalMinutes: point.totalMinutes))
                }
            )

            // Produce points for the month, zero-filling missing weeks, ordered by week start.
            let monthPoints: [FocusAnalyticsPoint] = weekStarts.map { ws in
                if let existing = index[ws] {
                    return existing
                } else {
                    return FocusAnalyticsPoint(date: ws, totalMinutes: 0)
                }
            }
            return monthPoints

        case .daily:
            // One calendar week per page, exactly 7 days, no overlap.
            let calendar = Calendar.current
            let latestDate = data.last?.date ?? Date()
            guard let targetRef = calendar.date(byAdding: .weekOfYear, value: -page, to: latestDate) else {
                return []
            }
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetRef) else {
                return []
            }
            let startOfWeek = calendar.startOfDay(for: weekInterval.start)
            let days: [Date] = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: startOfWeek).map { calendar.startOfDay(for: $0) }
            }
            let index: [Date: FocusAnalyticsPoint] = Dictionary(uniqueKeysWithValues:
                data.map { (calendar.startOfDay(for: $0.date), $0) }
            )
            let weekPoints: [FocusAnalyticsPoint] = days.map { day in
                if let existing = index[day] {
                    return existing
                } else {
                    return FocusAnalyticsPoint(date: day, totalMinutes: 0)
                }
            }
            return weekPoints
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
        case .weekly:
            // Count distinct months present in the data based on week start dates.
            let calendar = Calendar.current
            let monthKeys: [Date] = Array(Set(
                data.compactMap { point in
                    let weekStart = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
                    let normalized = calendar.startOfDay(for: weekStart)
                    return calendar.dateInterval(of: .month, for: normalized)?.start
                }
            )).sorted()
            // page 0 = most recent month; so maxPage = count - 1 (non-negative)
            return max(0, monthKeys.count - 1)

        case .daily:
            // Number of distinct calendar weeks present in the data,
            // minus 1 because page 0 is the most recent week.
            let calendar = Calendar.current
            let weekStarts: [Date] = Array(Set(
                data.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start }
            )).sorted()
            return max(0, weekStarts.count - 1)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with range and pager controls.
            HStack(spacing: 12) {
                Text(title).font(.headline)
                Spacer()
                if let first = visibleData.first?.date, let last = visibleData.last?.date {
                    Text(rangeLabel(start: first, end: last))
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
                    Text(label(for: selectedPoint.date))
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
                            Text(label(for: date))
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

    private func rangeLabel(start: Date, end: Date) -> String {
        let startLabel = start.formatted(.dateTime.month().day())
        let endLabel = end.formatted(.dateTime.month().day())
        switch granularity {
        case .daily:
            return "\(startLabel) - \(endLabel)"
        case .weekly:
            return "Weeks: \(startLabel) - \(endLabel)"
        }
    }

    private func label(for date: Date) -> String {
        switch granularity {
        case .daily:
            return date.formatted(.dateTime.weekday(.wide).month().day())
        case .weekly:
            return "Week of \(date.formatted(.dateTime.month().day()))"
        }
    }

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


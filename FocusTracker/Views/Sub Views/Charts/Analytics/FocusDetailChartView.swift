//CREATED  BY: nanthi13 ON 06/02/2026

import Foundation
import SwiftUI
import Charts

struct FocusDetailChartView: View {
    let title: String
    let data: [FocusAnalyticsPoint]
    let granularity: ChartGranularity
    let tasks: [PomodoroTaskModel]

    @State private var selectedPoint: FocusAnalyticsPoint?
    @State private var selectedTask: PomodoroTaskModel?

    // paging state: 0 = most recent window, 1 = previous window, etc.
    @State private var page: Int = 0

    private var windowSize: Int {
        switch granularity {
        case .daily: return 7
        case .weekly: return 6
        }
    }

    // Visible slice of data based on current page (most recent window when page == 0)
    private var visibleData: [FocusAnalyticsPoint] {
        let total = data.count
        guard total > 0 else { return [] }

        let size = windowSize
        let endIndex = total - 1 - page * size
        if endIndex < 0 {
            return []
        }
        let startIndex = max(0, endIndex - (size - 1))
        return Array(data[startIndex...endIndex])
    }

    // maximum page available (older pages)
    private var maxPage: Int {
        let total = data.count
        guard total > windowSize else { return 0 }
        // number of full/partial windows before the most recent one
        let extra = total - windowSize
        return Int((Double(extra) / Double(windowSize)).rounded(.up))
    }

    var body: some View {
        VStack(spacing: 12) {

            // header with small pager controls
            HStack(spacing: 12) {
                Text(title)
                    .font(.headline)

                Spacer()

                // show current range label
                if let first = visibleData.first?.date, let last = visibleData.last?.date {
                    Text(rangeLabel(start: first, end: last))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // pager buttons
                HStack(spacing: 8) {
                    Button {
                        // older (previous)
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
                        // newer (next)
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

            // Selected value readout
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

            Chart(visibleData) { point in
                FocusChartMarks.build(point: point, granularity: granularity)
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
            // detect swipe on the Chart itself to page windows (separate from overlay selection)
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
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x) {
                                        selectedPoint = closestPointInVisible(to: date)
                                        // map the selected analytics point to a concrete task (most recent on that date/week)
                                        if let selected = selectedPoint {
                                            selectedTask = taskFor(analyticsPoint: selected)
                                        } else {
                                            selectedTask = nil
                                        }
                                    }
                                }
                                .onEnded { value in
                                    // detect horizontal swipe to page through windows
                                    let translation = value.translation
                                    let predicted = value.predictedEndTranslation
                                    // lower threshold and consider swipe velocity/predicted end
                                    let threshold: CGFloat = 40
                                    if translation.width < -threshold || predicted.width < -threshold {
                                        // swipe left => older
                                        withAnimation {
                                            page = min(page + 1, maxPage)
                                            selectedPoint = nil
                                            selectedTask = nil
                                        }
                                    } else if translation.width > threshold || predicted.width > threshold {
                                        // swipe right => newer
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
        // Present TaskDetailView as a sheet when a concrete task is selected
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
            abs($0.date.timeIntervalSince(date)) <
            abs($1.date.timeIntervalSince(date))
        }
    }

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

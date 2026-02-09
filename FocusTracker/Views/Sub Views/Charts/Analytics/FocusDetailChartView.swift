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

    var body: some View {
        VStack(spacing: 16) {

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

            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Minutes", point.totalMinutes)
                )
                .cornerRadius(8)
                .foregroundStyle(
                    selectedPoint?.id == point.id
                    ? Color.accentColor.opacity(0.9) // still allowed as Color
                    : Color.secondary
                )
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
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x) {
                                        selectedPoint = closestPoint(to: date)
                                        // map the selected analytics point to a concrete task (most recent on that date/week)
                                        if let selected = selectedPoint {
                                            selectedTask = taskFor(analyticsPoint: selected)
                                        } else {
                                            selectedTask = nil
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 320)
            .padding(.horizontal)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        // Present TaskDetailView as a sheet when a concrete task is selected
        .sheet(item: $selectedTask) { task in
            // Provide the same onClose behavior so the close button inside the sheet dismisses it
            TaskDetailView(task: task, onClose: {
                selectedTask = nil
            })
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helpers

    private func label(for date: Date) -> String {
        switch granularity {
        case .daily:
            return date.formatted(.dateTime.weekday(.wide).month().day())
        case .weekly:
            return "Week of \(date.formatted(.dateTime.month().day()))"
        }
    }

    private func closestPoint(to date: Date) -> FocusAnalyticsPoint? {
        data.min {
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

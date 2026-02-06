//CREATED  BY: nanthi13 ON 06/02/2026

import Foundation
import SwiftUI
import Charts

struct FocusDetailChartView: View {
    let title: String
    let data: [FocusAnalyticsPoint]
    let granularity: ChartGranularity

    @State private var selectedPoint: FocusAnalyticsPoint?

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
}

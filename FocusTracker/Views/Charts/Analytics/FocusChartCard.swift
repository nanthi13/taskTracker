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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Chart(animatedData) { point in
                FocusChartMarks.build(point: point, granularity: granularity)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            switch granularity {
                            case .daily:
                                Text(date, format: .dateTime.weekday(.abbreviated))
                            case .weekly:
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
                animatedData = data
            }
        }
    }
}

// Note: FocusChartMarks and ChartGranularity are expected to be defined elsewhere.
// Ensure their APIs remain stable for reuse across card and detail chart views.


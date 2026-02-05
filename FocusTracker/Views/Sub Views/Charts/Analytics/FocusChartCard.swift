//CREATED  BY: nanthi13 ON 05/02/2026

import SwiftUI
import Charts

struct FocusChartCard: View {
    let title: String
    let data: [FocusAnalyticsPoint]
    let dateStride: Calendar.Component
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Minutes", point.totalMinutes)
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: dateStride)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.weekday(.abbreviated))
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
    }
    
}

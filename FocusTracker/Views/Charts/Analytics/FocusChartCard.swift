//CREATED  BY: nanthi13 ON 05/02/2026

import SwiftUI
import Charts

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
        .onTapGesture {
            onTap()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedData = data
            }
        }
    }
}

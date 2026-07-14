//CREATED  BY: nanthi13 ON 11/02/2026

import Foundation
import Charts
import SwiftUI

// extracting the chart marks into a separate struct to keep the code organized and reusable, this way we can easily switch between bar and line charts based on the granularity without cluttering the main chart view
struct FocusChartMarks {
    
    @ChartContentBuilder
    static func build(
        point: FocusAnalyticsPoint,
        granularity: ChartGranularity
    ) -> some ChartContent {
        
        switch granularity {
            
        case .daily:
            BarMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .cornerRadius(4)
            .annotation(position: .top) {
                Text("\(point.totalMinutes)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
        case .weekly:
            // Area for fill
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .opacity(0.15)
            
            // Line for trend
            LineMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.accentColor)
            
            // Point to anchor the annotation
            PointMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .symbol(.circle)
            .foregroundStyle(Color.accentColor)
            .annotation(position: .top) {
                Text("\(point.totalMinutes)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

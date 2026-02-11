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
            
        case .weekly:
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .opacity(0.15)
            
            LineMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .symbol(.circle)
            .interpolationMethod(.catmullRom)
        }
    }
}

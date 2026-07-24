//CREATED  BY: nanthi13 ON 11/02/2026

import Foundation
import Charts
import SwiftUI

// extracting the chart marks into a separate struct to keep the code organized and reusable, this way we can easily switch between bar and line charts based on the granularity without cluttering the main chart view
struct FocusChartMarks {
    
    @ChartContentBuilder
    static func build(
        point: FocusAnalyticsPoint,
        granularity: ChartGranularity,
        selectedDate: Date? = nil,
        isCompact: Bool = false
    ) -> some ChartContent {
        
        switch granularity {
            
        case .daily:
            BarMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .cornerRadius(4)
            .annotation(position: .top) {
                if !isCompact {
                    Text("\(point.totalMinutes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
        case .weekly:
            // Area for fill
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .opacity(isCompact ? 0.12 : 0.15)
            
            // Line for trend
            LineMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: isCompact ? 1.5 : 2))
            .foregroundStyle(Color.accentColor)
            
            // Point + selection styling
            let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: point.date) } ?? false
            PointMark(
                x: .value("Date", point.date),
                y: .value("Minutes", point.totalMinutes)
            )
            .symbol(.circle)
            .symbolSize(isSelected ? (isCompact ? 40 : 70) : (isCompact ? 20 : 35))
            .foregroundStyle(isSelected ? Color.accentColor : Color.accentColor.opacity(isCompact ? 0.7 : 0.8))
            .annotation(position: .top) {
                if !isCompact, isSelected {
                    Text("\(point.totalMinutes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}


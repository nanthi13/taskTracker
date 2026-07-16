// Created by: nanthi13 on 05/02/2026

import SwiftUI

/// Top-level analytics screen:
/// - Shows daily and weekly focus totals as cards.
/// - Navigates to a detail chart view with paging and selection.
/// - Accepts the full task list to compute analytics on demand.
struct AnalyticsDashboardView: View {
    @State private var path = NavigationPath()

    let tasks: [PomodoroTaskModel]

    /// Last 7 daily points (most recent).
    var dailyData: [FocusAnalyticsPoint] {
        tasks.dailyTotals().suffix(7)
    }

    /// Last 6 weekly points (most recent).
    var weeklyData: [FocusAnalyticsPoint] {
        tasks.weeklyTotals().suffix(6)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "No Focus Data Yet",
                        systemImage: "chart.bar",
                        description: Text("Complete a Pomodoro to see your analytics.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {

                            // New: Today's Sessions card
                            DailySessionsChartCard(tasks: tasks) {
                                // Optional: navigate to a dedicated "Day Detail" view later.
                                // For now, push daily detail with current week's window.
                                path.append(ChartGranularity.daily)
                            }

                            FocusChartCard(
                                title: "Daily Focus",
                                data: Array(dailyData),
                                granularity: .daily
                            ) { path.append(ChartGranularity.daily) }

                            FocusChartCard(
                                title: "Weekly Focus",
                                data: Array(weeklyData),
                                granularity: .weekly
                            ) { path.append(ChartGranularity.weekly) }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationDestination(for: ChartGranularity.self) { granularity in
                switch granularity {
                case .daily:
                    FocusDetailChartView(
                        title: "Daily Focus",
                        data: Array(tasks.dailyTotals()),
                        granularity: .daily,
                        tasks: tasks
                    )
                case .weekly:
                    FocusDetailChartView(
                        title: "Weekly Focus",
                        data: Array(tasks.weeklyTotals()),
                        granularity: .weekly,
                        tasks: tasks
                    )
                }
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let tasks = (0..<20).map {
        PomodoroTaskModel(
            name: "Task \($0)",
            duration: [25, 50, 75].randomElement()!,
            date: calendar.date(byAdding: .day, value: -Int.random(in: 0...10), to: now)!
        )
    }
    NavigationStack {
        AnalyticsDashboardView(tasks: tasks)
    }
}

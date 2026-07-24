// Created by: nanthi13 on 05/02/2026

import SwiftUI

/// Route for chart detail navigation carrying granularity and an optional anchor date,
/// or a day-sessions route that shows all sessions for a single day with paging.
enum ChartRoute: Hashable {
    case detail(granularity: ChartGranularity, anchorDate: Date?)
    case daySessions(anchorDate: Date)
}

/// Top-level analytics screen:
/// - Shows daily and weekly focus totals as cards.
/// - Navigates to a detail chart view with paging and selection.
/// - Accepts the full task list to compute analytics on demand.
struct AnalyticsDashboardView: View {
    @State private var path: [ChartRoute] = []

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

                            // Today's Sessions card -> DaySessionsDetailView with paging
                            DailySessionsChartCard(tasks: tasks) {
                                let anchor = Calendar.current.startOfDay(for: Date())
                                path.append(.daySessions(anchorDate: anchor))
                            }

                            FocusChartCard(
                                title: "Daily Focus",
                                data: Array(dailyData),
                                granularity: .daily
                            ) {
                                // Use the same anchor as the card uses internally: latest data date or today.
                                let anchor = dailyData.last?.date ?? Date()
                                path.append(.detail(granularity: .daily, anchorDate: anchor))
                            }

                            FocusChartCard(
                                title: "Weekly Focus",
                                data: Array(weeklyData),
                                granularity: .weekly
                            ) {
                                // Weekly ignores anchorDate, pass nil.
                                path.append(.detail(granularity: .weekly, anchorDate: nil))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationDestination(for: ChartRoute.self) { route in
                switch route {
                case let .detail(granularity, anchorDate):
                    switch granularity {
                    case .daily:
                        ScrollView {
                            FocusDetailChartView(
                                title: "Daily Focus",
                                data: Array(tasks.dailyTotals()),
                                granularity: .daily,
                                tasks: tasks,
                                anchorDate: anchorDate
                            )
                            
                            // currently hardcoded to show the day sessions for the anchor date if present
                            
                            DaySessionsDetailView(
                                title: "Day Sessions",
                                tasks: tasks,
                                anchorDate: anchorDate!
                            )
                        }
                    case .weekly:
                        FocusDetailChartView(
                            title: "Weekly Focus",
                            data: Array(tasks.weeklyTotals()),
                            granularity: .weekly,
                            tasks: tasks,
                            anchorDate: nil
                        )
                    }
                case let .daySessions(anchorDate):
                    DaySessionsDetailView(
                        title: "Day Sessions",
                        tasks: tasks,
                        anchorDate: anchorDate
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

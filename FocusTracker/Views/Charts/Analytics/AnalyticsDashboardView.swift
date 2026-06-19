//CREATED  BY: nanthi13 ON 05/02/2026

import SwiftUI

struct AnalyticsDashboardView: View {
    @State private var path = NavigationPath()

    let tasks: [PomodoroTaskModel]
    
    var dailyData: [FocusAnalyticsPoint] {
        tasks.dailyTotals().suffix(7) // past 7 days
    }
    
    var weeklyData: [FocusAnalyticsPoint] {
        tasks.weeklyTotals().suffix(6) // past 6 weeks
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
                            FocusChartCard(
                                title: "Daily Focus", data: Array(dailyData), granularity: .daily ) { path.append(ChartGranularity.daily)
                                }
                            
                            FocusChartCard(title: "Weekly Focus", data: Array(weeklyData), granularity: .weekly) {
                                path.append(ChartGranularity.weekly)
                            }
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
                        // pass full series so the detail view can page through older windows
                        data: Array(tasks.dailyTotals()),
                        granularity: .daily,
                        tasks: tasks
                    )
                    
                case .weekly:
                    FocusDetailChartView(
                        title: "Weekly Focus",
                        // pass full series so the detail view can page through older windows
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
    
    NavigationStack{
        AnalyticsDashboardView(tasks: tasks)
    }
}

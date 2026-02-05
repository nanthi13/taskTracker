//CREATED  BY: nanthi13 ON 05/02/2026

import SwiftUI

struct AnalyticsDashboardView: View {
    let tasks: [PomodoroTaskModel]
    
    var dailyData: [FocusAnalyticsPoint] {
        tasks.dailyTotals().suffix(7) // past 7 days
    }
    
    var weeklyData: [FocusAnalyticsPoint] {
        tasks.weeklyTotals().suffix(6) // past 6 weeks
    }
    
    var body: some View {
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
                            title: "Daily Focus", data: Array(dailyData), dateStride: .day)
                        
                        FocusChartCard(title: "Weekly Focus", data: Array(weeklyData), dateStride: .weekOfYear)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Analytics")
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

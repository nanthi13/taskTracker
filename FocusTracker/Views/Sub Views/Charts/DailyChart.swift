//CREATED  BY: nanthi13 ON 04/02/2026

import SwiftUI
import Charts

struct DailyChart: View {
    @ObservedObject var dataManager: DataManager

    var body: some View {
        Chart(dataManager.tasks) { task in
            BarMark(
                x: .value("Date", task.date),
                y: .value("Duration", task.duration/60)
            )
            
        }
        .frame(height: 250)
        .padding()
    }
}


#Preview {
    let dataManager = DataManager()
    DailyChart(dataManager: dataManager)
}

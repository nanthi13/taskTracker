//CREATED  BY: nanthi13 ON 29/01/2026

import SwiftUI
import Charts

struct ChartView: View {
    
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        ScrollView {
            VStack{
                HStack {
                    DailyChart(dataManager: dataManager)
                        .frame(height: 300)
                    
                    WeeklyChart()
                        .frame(height: 300)
                }
            }
        }
    }
}
    
    #Preview {
        var dataManager = DataManager()
        
        ChartView(dataManager: dataManager)
}


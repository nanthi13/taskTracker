//CREATED  BY: nanthi13 ON 20/01/2026

import SwiftUI

struct AppViewCopy: View {
    
    @State private var selectedTab: AppTab = .home
    
    @StateObject private var dataManager: DataManager
        @StateObject private var timerManager: TimerManager

        init() {
            let manager = DataManager()
            _dataManager = StateObject(wrappedValue: manager)
            _timerManager = StateObject(
                wrappedValue: TimerManager(dataManager: manager)
            )
        }
    
    // adding custom minute selection
    @State private var selectedFocusMinutes: Int = 25
    @State private var selectedBreakMinutes: Int = 5
    
    // computed durations selected from the pickers
    private var focusDuration: Int { selectedFocusMinutes * 60 }
    private var breakDuration: Int { selectedBreakMinutes * 60 }
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    selectedTab: $selectedTab,
                    timerManager: timerManager,
                    dataManager: dataManager)
            }
            .tabItem {
                Label("Home", systemImage: "timer")
            }
            .tag(AppTab.home)
            
            NavigationStack {
                ChartView(dataManager: dataManager)
            }
            .tabItem {
                Label("Charts", systemImage: "chart.bar.fill")
            }
            
            NavigationStack {
                TaskHistoryView(dataManager: dataManager)
            }
            .tabItem {
                Label("History", systemImage: "tray.and.arrow.up.fill")
            }
            .tag(AppTab.history)
            
            // PROFILE TAB
            NavigationStack {
                AnalyticsDashboardView(tasks: dataManager.tasks)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(AppTab.profile)
            
        }
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


#Preview {
    AppViewCopy()
}

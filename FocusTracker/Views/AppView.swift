// Created by: nanthi13 on 20/01/2026

import SwiftUI

/// Root tab container for the application.
/// - Hosts Home, Analytics, History, Profile, and a Testing tab (for development).
/// - Shares a single DataManager and TimerManager across tabs via StateObject.
struct AppView: View {

    @State private var selectedTab: AppTab = .home

    @StateObject private var dataManager: DataManager
    @StateObject private var timerManager: TimerManager

    init() {
        let manager = DataManager()
        _dataManager = StateObject(wrappedValue: manager)
        _timerManager = StateObject(wrappedValue: TimerManager(dataManager: manager))
    }

    // Picker defaults (unused externally; TimerManager owns active values).
    @State private var selectedFocusMinutes: Int = 25
    @State private var selectedBreakMinutes: Int = 5

    // Force rebuild of charts when mock data loads in Testing tab.
    @State private var chartsRefreshID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    selectedTab: $selectedTab,
                    timerManager: timerManager,
                    dataManager: dataManager
                )
            }
            .tabItem { Label("Home", systemImage: "timer") }
            .tag(AppTab.home)

            NavigationStack {
                AnalyticsDashboardView(tasks: dataManager.tasks)
                    .id(chartsRefreshID)
            }
            .tabItem { Label("Charts", systemImage: "chart.bar.fill") }
            .tag(AppTab.charts)

            NavigationStack {
                TaskHistoryView(dataManager: dataManager)
            }
            .tabItem { Label("History", systemImage: "tray.and.arrow.up.fill") }
            .tag(AppTab.history)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            .tag(AppTab.profile)

            // Development/testing tab: load mock data and inspect charts/history.
            NavigationStack {
                VStack {
                    Button("load data for multiple sessions") {
                        dataManager.loadMultipleTasksForSameDay()
                        chartsRefreshID = UUID()

                }
                    .buttonStyle(.borderedProminent)
                    
                    Button("load Data for weeks") {
//                        let weeks = 30
                        dataManager.loadMockDataSpanningWeeks(weeks: 30)
                        chartsRefreshID = UUID()
                        selectedTab = .testing
                    }
                    .buttonStyle(.borderedProminent)
                }

                VStack {
                    AnalyticsDashboardView(tasks: dataManager.tasks)
                        .id(chartsRefreshID)
                        .padding()
                    TaskHistoryView(dataManager: dataManager)
                }
            }
            .tabItem { Label("Testing", systemImage: "wrench.and.screwdriver.fill") }
            .tag(AppTab.testing)
        }
        .monospaced()
        .environmentObject(dataManager)
    }

    /// Formats seconds as mm:ss.
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    AppView()
}


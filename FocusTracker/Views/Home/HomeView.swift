// Created by: nanthi13 on 29/01/2026

import SwiftUI

/// Main home screen:
/// - Shows current mode (Focus/Break) and a circular progress ring.
/// - Allows naming the task and choosing focus/break durations when idle.
/// - Exposes accessibility identifiers used by UI tests.
/// - Hosts recent tasks card for quick access to history items.
struct HomeView: View {

    @Binding var selectedTab: AppTab

    @ObservedObject var timerManager: TimerManager
    @ObservedObject var dataManager: DataManager

    private var progress: Double {
        timerManager.animatedProgress
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 30) {
                    Text("Focus Tracker App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(timerManager.taskName.isEmpty ? 1 : 0)
                        .opacity(timerManager.state == .idle ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: timerManager.taskName)

                    Text(timerManager.mode == .breakTime ? "Break Time" : "Focus Time")
                        .font(.largeTitle)
                        .accessibilityIdentifier("timerModeLabel")
                        .id("focusTime")

                    // Task name entry when idle in focus mode.
                    if timerManager.state == .idle && timerManager.mode == .focus {
                        TaskNameTextField(text: $timerManager.taskName)
                            .onSubmit {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo("focusTime", anchor: .top)
                                }
                            }
                            .padding(.horizontal)
                            .accessibilityIdentifier("taskNameField")
                    } else {
                        Text(timerManager.taskName)
                            .font(.title2)
                            .italic()
                            .foregroundColor(.gray)
                            .accessibilityLabel("timerTitle")
                    }

                    // Circular progress and remaining time.
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 220, height: 220)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(timerManager.mode == .breakTime ? Color.blue : Color.green,
                                    style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 220, height: 220)

                        Text(timeString(from: timerManager.timeRemaining))
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .padding(.vertical)
                            .accessibilityIdentifier("timerTimeLabel")
                    }

                    // Duration pickers when idle in focus mode.
                    if timerManager.state == .idle && timerManager.mode == .focus {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Focus Duration")
                                        .font(.headline)
                                    Picker("Focus Duration", selection: $timerManager.selectedFocusMinutes) {
                                        ForEach(1...60, id: \.self) { minute in
                                            Text("\(minute) min").tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 100, height: 120)
                                    .clipped()
                                    .accessibilityIdentifier("focusPicker")
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Break Duration")
                                        .font(.headline)
                                    Picker("Break Duration", selection: $timerManager.selectedBreakMinutes) {
                                        ForEach(1...30, id: \.self) { minute in
                                            Text("\(minute) min").tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 100, height: 120)
                                    .clipped()
                                    .accessibilityIdentifier("breakPicker")
                                }
                            }
                            .padding(.horizontal)
                        }
                        .onChange(of: timerManager.selectedFocusMinutes) {
                            // Keep initial time in sync with picker while idle.
                            timerManager.timeRemaining = timerManager.selectedFocusMinutes * 60
                        }
                    } else {
                        HStack {
                            Text("Focus: \(timerManager.selectedFocusMinutes) min")
                            Spacer()
                            Text("Break: \(timerManager.selectedBreakMinutes) min")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    }

                    // Start/Pause/Reset/Resume controls.
                    StartStopButtonsView(
                        state: timerManager.state,
                        start: timerManager.startTimer,
                        pause: timerManager.pauseTimer,
                        reset: timerManager.resetTimer,
                        resume: timerManager.resumeTimer,
                        endSession: timerManager.endFocusSessionEarly,
                        scrollProxy: proxy
                    )

                    Spacer()

                    // Recent tasks card (top 3).
                    RecentTasksCardView(dataManager: dataManager, selectedTab: $selectedTab)
                        .padding()
                        .accessibilityIdentifier("taskHistoryTab")
                }
            }
        }
    }

    /// Formats seconds as mm:ss.
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    // Provide a preview in AppView.
}


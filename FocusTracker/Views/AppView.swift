//CREATED  BY: nanthi13 ON 20/01/2026

import SwiftUI

struct AppView: View {
    
    @StateObject private var dataManager: DataManager
    @StateObject private var timerManager: TimerManager

    init() {
        let manager = DataManager()
        _dataManager = StateObject(wrappedValue: manager)
        _timerManager = StateObject(wrappedValue: TimerManager(dataManager: manager))
    }

    
    // adding custom minute selection
    @State private var selectedFocusMinutes: Int = 25
    @State private var selectedBreakMinutes: Int = 5
    
    // computed durations selected from the pickers
    private var focusDuration: Int { selectedFocusMinutes * 60 }
    private var breakDuration: Int { selectedBreakMinutes * 60 }
    
    private var progress: Double {
        timerManager.animatedProgress
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if timerManager.taskName.isEmpty {
                        Text("Focus Tracker App")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .transition(.opacity)
                    }
                    Text(timerManager.mode == .breakTime ? "Break Time" : "Focus Time")
                        .font(.largeTitle)
                        .accessibilityIdentifier("timerModeLabel")
                    
                    // naming the task
                    if timerManager.state == .idle && timerManager.mode == .focus {
                        TextField("Enter task name: " , text:
                                    $timerManager.taskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .accessibilityIdentifier("taskNameField")
                    } else {
                        Text(timerManager.taskName)
                            .font(.title2)
                            .italic()
                            .foregroundColor(.gray)
                            .accessibilityLabel("timerTitle")
                    }
                    ZStack {
                        // Circle
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(timerManager.mode == .breakTime ? Color.blue : Color.green,
                                    style: StrokeStyle(lineWidth: 15, lineCap:.round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 220, height: 220)
                        
                        Text(timeString(from: timerManager.timeRemaining))
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .padding(.vertical)
                            .accessibilityIdentifier("timerTimeLabel")
                    }
                    // timer pickers
                    
                    if timerManager.state == .idle && timerManager.mode == .focus {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Focus Duration")
                                        .font(.headline)
                                    // building timer picker
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
                    
                    StartStopButtonsView(state: timerManager.state, start: timerManager.startTimer, pause: timerManager.pauseTimer, reset: timerManager.resetTimer, resume: timerManager.resumeTimer)
                    Spacer()
                    
                    // taskhistoryView
                    NavigationLink("View Task History") {
                        TaskHistoryView(dataManager: dataManager)
                    }
                    .padding()
                    .accessibilityIdentifier("taskHistoryLink")
                }
            }
        }
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    AppView()
}

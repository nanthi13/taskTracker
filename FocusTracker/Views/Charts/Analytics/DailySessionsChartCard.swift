// Created by: nanthi13 on 14/07/2026

import SwiftUI
import Charts

/// Compact chart card showing all focus sessions that occurred today.
/// - One mark per completed session (duration in minutes).
/// - Animates in on appear.
/// - Tapping the card invokes onTap (optional navigation to a day detail view).
struct DailySessionsChartCard: View {
    let tasks: [PomodoroTaskModel]
    let title: String = "Today's Sessions"
    let onTap: () -> Void

    @State private var animatedSessions: [SessionPoint] = []

    private var todaySessions: [SessionPoint] {
        let calendar = Calendar.current
        let todays = tasks.filter { calendar.isDateInToday($0.date) }
        // Map to session points (start time and duration minutes).
        return todays
            .sorted(by: { $0.date < $1.date })
            .map { SessionPoint(start: $0.date, minutes: max(1, $0.duration / 60)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if animatedSessions.isEmpty {
                ContentUnavailableView(
                    "No sessions today",
                    systemImage: "calendar",
                    description: Text("Start a focus session to see it here.")
                )
                .frame(height: 110)
            } else {
                Chart(animatedSessions) { session in
                    BarMark(
                        x: .value("Start", session.start),
                        y: .value("Minutes", session.minutes)
                    )
                    .cornerRadius(3)
                    .foregroundStyle(Color.accentColor.opacity(0.85))
                    .annotation(position: .top) {
                        Text("\(session.minutes)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 110)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { onTap() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animatedSessions = todaySessions
            }
        }
        .onChange(of: tasks) {
            withAnimation(.easeOut(duration: 0.6)) {
                animatedSessions = todaySessions
            }
        }
    }
}

// Lightweight data for the daily sessions chart.
private struct SessionPoint: Identifiable, Equatable {
    let id = UUID()
    let start: Date
    let minutes: Int
}

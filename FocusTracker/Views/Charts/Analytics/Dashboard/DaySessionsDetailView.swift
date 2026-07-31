// DaySessionsDetailView.swift
import SwiftUI
import Charts

/// DaySessionsDetailView
/// A focused, session-level detail view for a single calendar day with horizontal paging.
/// Purpose:
/// - Presents all focus sessions that occurred on a specific day (anchorDate initially).
/// - Allows paging day-by-day (left/right) to inspect earlier/later days that exist in the dataset.
/// - Visualizes sessions as a bar chart (one bar per session, height = duration in minutes).
/// - Lists the same sessions beneath the chart for quick scanning and tap-to-open details.
/// - Supports selection via chart tap (nearest session by x-position) and via list row tap.
/// - Presents TaskDetailView using the shared .taskDetailSheet modifier.
///
/// Paging model:
/// - page == 0 represents anchorDate (normalized to startOfDay).
/// - page increases when paging backward in time (earlier days): currentDate = anchorDate - page days.
/// - page decreases (towards 0) when paging forward in time (later days), clamped to available dates.
/// - Paging is bounded by the earliest and latest task dates in the provided tasks array.
///
/// Notes:
/// - The chart + list are wrapped in a ScrollView so the list remains usable with many sessions.
/// - This view is intentionally session-based and separate from FocusDetailChartView, which is
///   an aggregated totals view (daily/weekly buckets).
struct DaySessionsDetailView: View {
    /// Title shown in the navigation bar and header (e.g., "Day Sessions").
    let title: String

    /// Full task dataset from which this view filters the sessions for the current day.
    let tasks: [PomodoroTaskModel]

    /// The initial date to display (page 0). The view normalizes this to the start of the day.
    let anchorDate: Date

    /// Current page offset. 0 = anchor day, 1 = previous day, etc.
    @State private var page: Int = 0

    /// Selected task for presenting TaskDetailView via the shared sheet modifier.
    @State private var selectedTask: PomodoroTaskModel?

    private var calendar: Calendar { Calendar.current }

    /// Inclusive bounds of available days in the dataset, normalized to start-of-day.
    /// Used to clamp paging so we never go beyond the data range.
    private var dateBounds: (min: Date, max: Date)? {
        guard let minDate = tasks.min(by: { $0.date < $1.date })?.date,
              let maxDate = tasks.max(by: { $0.date < $1.date })?.date else {
            return nil
        }
        let startMin = calendar.startOfDay(for: minDate)
        let startMax = calendar.startOfDay(for: maxDate)
        return (min: startMin, max: startMax)
    }

    /// The day currently displayed, computed from anchorDate and page offset,
    /// normalized to start-of-day to ensure consistent filtering.
    private var currentDate: Date {
        let base = calendar.startOfDay(for: anchorDate)
        return calendar.date(byAdding: .day, value: -page, to: base).map { calendar.startOfDay(for: $0) } ?? base
    }

    /// All sessions (tasks) on the current day, ordered by start time ascending.
    private var daySessions: [PomodoroTaskModel] {
        tasks.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
             .sorted(by: { $0.date < $1.date })
    }

    /// Sum of minutes for the current day's sessions.
    private var totalMinutes: Int {
        daySessions.reduce(0) { $0 + max(1, $1.duration / 60) }
    }

    /// True if we can page forward (towards later days, i.e., decrease page toward 0).
    /// Always allow moving toward the anchor (page == 0). Only clamp when attempting to go beyond the anchor.
    private var canPageForward: Bool {
        if page > 0 {
            // Always allow returning toward the anchor day.
            return true
        }
        // When already at anchor (page == 0), only allow moving to even later days if within dataset (not used currently).
        guard let bounds = dateBounds,
              let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            return false
        }
        return calendar.startOfDay(for: nextDate) <= bounds.max
    }

    /// True if we can page backward (towards earlier days).
    private var canPageBackward: Bool {
        guard let bounds = dateBounds else { return false }
        guard let prevDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { return false }
        return calendar.startOfDay(for: prevDate) >= bounds.min
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with date and pager controls
            HStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                Spacer()
                // Current date label (weekday + month/day/year)
                Text(currentDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    // Page backward (earlier day)
                    Button {
                        withAnimation {
                            if canPageBackward { page += 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .disabled(!canPageBackward)

                    // Page forward (later day, i.e., toward anchor)
                    Button {
                        withAnimation {
                            if page > 0 {
                                page -= 1
                            } else if canPageForward {
                                // Optional: move beyond anchor into future if allowed; not typical
                                page = max(0, page - 1)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .disabled(!(page > 0 || canPageForward))
                }
            }
            .padding(.horizontal)

            // Summary row: number of sessions + total minutes for the day.
            HStack {
                Text("\(daySessions.count) session\(daySessions.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalMinutes) min total")
                    .font(.headline)
            }
            .padding(.horizontal)

            if daySessions.isEmpty {
                // Empty state for the selected day.
                ContentUnavailableView(
                    "No sessions",
                    systemImage: "calendar",
                    description: Text("No focus sessions on this day.")
                )
                .frame(height: 220)
                .padding(.horizontal)
            } else {
                // Scrollable content: chart + sessions list
                ScrollView {
                    VStack(spacing: 16) {
                        // Chart: one bar per session, height = duration minutes.
                        Chart(daySessions, id: \.id) { task in
                            BarMark(
                                x: .value("Start", task.date),
                                y: .value("Minutes", max(1, task.duration / 60))
                            )
                            .cornerRadius(4)
                            .foregroundStyle(Color.accentColor.opacity(0.85))
                            .annotation(position: .top) {
                                Text("\(max(1, task.duration / 60))")
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
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        // Add a bit more bottom padding to avoid clipping x-axis labels.
                        .chartPlotStyle { plotArea in
                            plotArea
                                .padding(.bottom, 12)
                        }
                        .frame(height: 330)
                        .padding(.horizontal)

                        // Sessions list under the chart (mirrors the chart content).
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sessions")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(daySessions) { task in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("\(max(1, task.duration / 60)) min")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(task.date, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.08))
                                )
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                // Row tap also presents TaskDetailView.
                                .onTapGesture { selectedTask = task }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        // Presents TaskDetailView when a task is selected from chart or list.
        .taskDetailSheet(selectedTask: $selectedTask)
        // Swipe to page days (left = forward, right = backward).
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let threshold: CGFloat = 40
                    if value.translation.width < -threshold {
                        // swipe left -> go to next (later) day if possible
                        if page > 0 {
                            withAnimation { page -= 1 }
                        } else if canPageForward {
                            withAnimation { page = max(0, page - 1) }
                        }
                    } else if value.translation.width > threshold {
                        // swipe right -> go to previous (earlier) day if possible
                        if canPageBackward {
                            withAnimation { page += 1 }
                        }
                    }
                }
        )
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    // More sessions to demonstrate scrolling in the preview.
    let tasks: [PomodoroTaskModel] = (0..<18).map { i in
        let hour = 8 + (i % 10)
        let date = calendar.date(bySettingHour: hour, minute: (i * 7) % 60, second: 0, of: today)!
        return PomodoroTaskModel(name: "Task \(i+1)", duration: [600, 900, 1200].randomElement()!, date: date)
    }
    return NavigationStack {
        DaySessionsDetailView(title: "Day Sessions", tasks: tasks, anchorDate: today)
    }
}


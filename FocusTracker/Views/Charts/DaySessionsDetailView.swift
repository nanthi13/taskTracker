// DaySessionsDetailView.swift
import SwiftUI
import Charts

/// Detail view showing all sessions for a single day, with day-by-day paging.
/// - One bar per session (duration minutes) on the selected day.
/// - Swipe horizontally or use chevrons to move to previous/next day within the task date bounds.
/// - Tap a bar or a row to present the TaskDetailView sheet.
/// - Chart + Sessions list are scrollable together.
struct DaySessionsDetailView: View {
    let title: String
    let tasks: [PomodoroTaskModel]
    let anchorDate: Date

    @State private var page: Int = 0 // 0 = anchor day, 1 = previous day, etc.
    @State private var selectedTask: PomodoroTaskModel?

    private var calendar: Calendar { Calendar.current }

    /// Earliest and latest days present in tasks (start-of-day normalized).
    private var dateBounds: (min: Date, max: Date)? {
        guard let minDate = tasks.min(by: { $0.date < $1.date })?.date,
              let maxDate = tasks.max(by: { $0.date < $1.date })?.date else {
            return nil
        }
        let startMin = calendar.startOfDay(for: minDate)
        let startMax = calendar.startOfDay(for: maxDate)
        return (min: startMin, max: startMax)
    }

    /// The date for the current page (start-of-day).
    private var currentDate: Date {
        let base = calendar.startOfDay(for: anchorDate)
        return calendar.date(byAdding: .day, value: -page, to: base).map { calendar.startOfDay(for: $0) } ?? base
    }

    /// Sessions on the current day, ordered by start time.
    private var daySessions: [PomodoroTaskModel] {
        tasks.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
             .sorted(by: { $0.date < $1.date })
    }

    /// Total minutes for the current day.
    private var totalMinutes: Int {
        daySessions.reduce(0) { $0 + max(1, $1.duration / 60) }
    }

    /// Whether we can page forward (to a later day).
    private var canPageForward: Bool {
        guard let bounds = dateBounds else { return false }
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { return false }
        return calendar.startOfDay(for: nextDate) <= bounds.max
    }

    /// Whether we can page backward (to an earlier day).
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
                Text(currentDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
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

                    Button {
                        withAnimation {
                            if page > 0, canPageForward { page -= 1 }
                            else if page == 0 {
                                if canPageForward { page = max(0, page - 1) }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .disabled(!canPageForward || (page == 0 && !canPageForward))
                }
            }
            .padding(.horizontal)

            // Summary row
            HStack {
                Text("\(daySessions.count) session\(daySessions.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalMinutes) min total")
                    .font(.headline)
            }
            .padding(.horizontal)

            if daySessions.isEmpty {
                ContentUnavailableView(
                    "No sessions",
                    systemImage: "calendar",
                    description: Text("No focus sessions on this day.")
                )
                .frame(height: 220)
                .padding(.horizontal)
            } else {
                // Make the chart + list scrollable together
                ScrollView {
                    VStack(spacing: 16) {
                        // Chart
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
                        // Selection overlay: tap to pick nearest session by X
                        .chartOverlay { proxy in
                            GeometryReader { _ in
                                Rectangle()
                                    .fill(.clear)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { value in
                                                let location = value.location
                                                if let date: Date = proxy.value(atX: location.x) {
                                                    if let nearest = daySessions.min(by: {
                                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                                    }) {
                                                        selectedTask = nearest
                                                    }
                                                }
                                            }
                                    )
                            }
                        }
                        .frame(height: 280)
                        .padding(.horizontal)

                        // Sessions list under the chart
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
        .taskDetailSheet(selectedTask: $selectedTask)
        // Swipe to page days
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let threshold: CGFloat = 40
                    if value.translation.width < -threshold {
                        // swipe left -> go to next (later) day if possible
                        if canPageForward {
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
    let tasks: [PomodoroTaskModel] = (0..<18).map { i in
        let hour = 8 + (i % 10) // more to show scrolling
        let date = calendar.date(bySettingHour: hour, minute: (i * 7) % 60, second: 0, of: today)!
        return PomodoroTaskModel(name: "Task \(i+1)", duration: [600, 900, 1200].randomElement()!, date: date)
    }
    return NavigationStack {
        DaySessionsDetailView(title: "Day Sessions", tasks: tasks, anchorDate: today)
    }
}

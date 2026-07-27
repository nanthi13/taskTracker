// Created by: nanthi13 on 20/01/2026

import SwiftUI

/// Displays previously completed focus sessions and allows deletion.
/// - Search/filter by task name and date range (All, Today, This Week).
/// - Groups tasks by day with section headers (Today, Yesterday, or date).
/// - Exposes a "Clear All" destructive action with confirmation.
/// - Presents a task detail sheet when a row is tapped.
struct TaskHistoryView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showClearAlert = false
    @State private var selectedTask: PomodoroTaskModel? = nil

    // Filtering
    @State private var searchText: String = ""
    @State private var dateFilter: DateFilter = .all

    private var calendar: Calendar { .current }

    enum DateFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case week = "This Week"

        var id: String { rawValue }
    }

    // Apply text and date filtering to the tasks list.
    private var filteredTasks: [PomodoroTaskModel] {
        var items = dataManager.tasks

        // Date filter
        switch dateFilter {
        case .all:
            break
        case .today:
            items = items.filter { calendar.isDateInToday($0.date) }
        case .week:
            if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
               let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) {
                items = items.filter { $0.date >= startOfWeek && $0.date < endOfWeek }
            }
        }

        // Search filter (by task name)
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            items = items.filter { $0.name.lowercased().contains(query) }
        }

        return items
    }

    /// Tasks grouped by start-of-day, sorted with most recent day first.
    /// Each section’s tasks are sorted by time descending (most recent first).
    private var groupedTasks: [(day: Date, tasks: [PomodoroTaskModel])] {
        let groups = Dictionary(grouping: filteredTasks) { task in
            calendar.startOfDay(for: task.date)
        }

        let sortedDays = groups.keys.sorted(by: >) // most recent day first
        return sortedDays.map { day in
            let tasks = (groups[day] ?? []).sorted(by: { $0.date > $1.date })
            return (day: day, tasks: tasks)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Filter controls
            VStack(spacing: 12) {

                // Pill chips for date filtering (dynamic width, scrollable)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DateFilter.allCases) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: dateFilter == filter
                            ) {
                                withAppropriateAnimation {
                                    dateFilter = filter
                                }
                            }
                            // Animated appearance changes
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent) // tighter scroll content

                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search tasks", text: $searchText)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) { _ in
                            withAppropriateAnimation { }
                        }
                    if !searchText.isEmpty {
                        Button {
                            withAppropriateAnimation {
                                searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            }
            .padding(.top, 8)

            // Results list
            List {
                if filteredTasks.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No tasks found",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Adjust your filters or try a different search.")
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets())
                    }
                    .transition(.opacity)
                } else {
                    ForEach(groupedTasks, id: \.day) { section in
                        Section(header: Text(sectionHeader(for: section.day))) {
                            ForEach(section.tasks) { task in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .contentTransition(.numericText()) // smoother weight/size transitions
                                        // Show only time since date is implied by the section
                                        Text("Focused for \(timeString(from: task.duration)) • \(task.date.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("taskRow_\(task.name)")
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedTask = task }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                            // Map delete offsets to underlying indices in dataManager.tasks
                            .onDelete { offsets in
                                withAppropriateAnimation {
                                    deleteTasks(in: section.day, offsets: offsets)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .animation(appropriateListAnimation, value: groupedTasks.map(\.day)) // animate section changes
            .animation(appropriateListAnimation, value: filteredTasks.count)      // animate row changes
        }
        .monospaced()
        .accessibilityIdentifier("taskHistoryList")
        .navigationTitle("Task History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .accessibilityIdentifier("clearAllButton")
                .disabled(dataManager.tasks.isEmpty)
            }
        }
        .alert("Clear all tasks?", isPresented: $showClearAlert) {
            Button("Delete All", role: .destructive) {
                withAppropriateAnimation {
                    dataManager.clearAllTasks()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        // Present the TaskDetailView as a sheet.
        .taskDetailSheet(selectedTask: $selectedTask)
    }

    // MARK: - Helpers

    /// Formats seconds as mm:ss.
    func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Section header label: Today, Yesterday, or full date.
    private func sectionHeader(for day: Date) -> String {
        if calendar.isDateInToday(day) {
            return "Today"
        } else if calendar.isDateInYesterday(day) {
            return "Yesterday"
        } else {
            return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
        }
    }

    /// Deletes tasks at offsets within a given day section, mapping to indices in dataManager.tasks.
    private func deleteTasks(in day: Date, offsets: IndexSet) {
        let startOfDay = calendar.startOfDay(for: day)
        // Build the list of tasks for that day in the same order shown (date descending).
        let sectionTasks = dataManager.tasks
            .filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
            .sorted(by: { $0.date > $1.date })

        // Map the offsets to the concrete tasks being deleted.
        let tasksToDelete = offsets.compactMap { index in
            sectionTasks.indices.contains(index) ? sectionTasks[index] : nil
        }

        // Translate to indices in the master array and remove.
        for task in tasksToDelete {
            dataManager.removeTask(task)
        }
    }

    // Choose modern animations on newer OS versions, with fallback.
    private var appropriateListAnimation: Animation {
        if #available(iOS 18.0, macOS 15.0, *) {
            return .bouncy(duration: 0.35, extraBounce: 0.02)
        } else {
            return .easeInOut(duration: 0.25)
        }
    }

    private func withAppropriateAnimation(_ updates: @escaping () -> Void) {
        if #available(iOS 18.0, macOS 15.0, *) {
            withAnimation(.snappy(duration: 0.22, extraBounce: 0.03), updates)
        } else {
            withAnimation(.easeInOut(duration: 0.2), updates)
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .contentTransition(.interpolate) // smooth weight change on iOS 18+
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .scaleEffect(isSelected ? 0.98 : 1.0)
            .animation(
                {
                    if #available(iOS 18.0, macOS 15.0, *) {
                        return .snappy(duration: 0.18, extraBounce: 0.02)
                    } else {
                        return .easeInOut(duration: 0.18)
                    }
                }(),
                value: isSelected
            )
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

#Preview {
    let mockData = DataManager()
    mockData.tasks = [
        PomodoroTaskModel(name: "Design UI", duration: 25 * 60, date: Date().addingTimeInterval(-3600)),
        PomodoroTaskModel(name: "Write Documentation", duration: 15 * 60, date: Date().addingTimeInterval(-7200)),
        PomodoroTaskModel(name: "Debug Timer", duration: 10 * 60, date: Date().addingTimeInterval(-10800)),
        PomodoroTaskModel(name: "Yesterday Task", duration: 20 * 60, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        PomodoroTaskModel(name: "Last Week Task", duration: 30 * 60, date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
    ]
    return NavigationStack {
        TaskHistoryView(dataManager: mockData)
            .accessibilityIdentifier("taskHistoryList")
    }
}

// Created by: nanthi13 on 19/06/2026

import SwiftUI

/// Placeholder profile screen.
/// TODO:
/// - Persist and display user profile details (name, email, avatar)
/// - Edit profile and change password flows
/// - Show stats such as longest task and average focus time
/// - Provide dynamic encouragement based on recent focus performance
///
struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var profileStore: ProfileStore

    @State private var isEditingName: Bool = false

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard
                encouragementCard
                Spacer(minLength: 12)
            }
            .padding()
        }
        .navigationTitle("Profile")
    }

    // MARK: - Cards

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                // Placeholder avatar
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if isEditingName {
                        HStack(spacing: 8) {
                            TextField("Your name", text: Binding(
                                get: { profileStore.user.displayName },
                                set: { profileStore.user.displayName = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { isEditingName = false }
                            .submitLabel(.done)

                            Button("Save") {
                                withAnimation { isEditingName = false }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(profileStore.user.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Text(profileStore.user.displayName.isEmpty ? "Your Name" : profileStore.user.displayName)
                                .font(.headline)
                            Button {
                                withAnimation { isEditingName = true }
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("editDisplayNameButton")
                        }
                    }

                    // Streak row
                    HStack(spacing: 8) {
                        let streak = currentFocusStreak(tasks: dataManager.tasks)
                        Label {
                            Text("\(streak) day\(streak == 1 ? "" : "s") streak")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(streak > 0 ? .orange : .secondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .accessibilityIdentifier("focusStreakLabel")
                    }
                }

                Spacer()
            }

            Divider()

            // Reuse Analytics summary cards for consistency.
            HStack(spacing: 10) {
                FocusSummaryCard(
                    title: "Focus Hrs",
                    minutes: dataManager.tasks.totalFocusMinutes(),
                    systemImage: "clock",
                    tint: .blue
                )

                FocusSummaryCard(
                    title: "Sessions Today",
                    valueText: dataManager.tasks.amountOfSessionsToday(calendar: calendar),
                    systemImage: "list.bullet",
                    tint: .purple
                )

                FocusSummaryCard(
                    title: "Avg Today",
                    minutes: dataManager.tasks.averageSessionTodayMinutes(calendar: calendar),
                    systemImage: "chart.bar",
                    tint: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityIdentifier("profileCard")
    }

    private var encouragementCard: some View {
        let streak = currentFocusStreak(tasks: dataManager.tasks)
        let message: String = {
            switch streak {
            case 0:
                return "Start your first focus session today!"
            case 1...3:
                return "Nice start! Keep the momentum going."
            case 4...6:
                return "Great work! You're building a strong habit."
            case 50...100:
                return "Nothing can stop you now! Keep it up!"
            case 101...250:
                return "Learning is your superpower! Keep going!"
            default:
                return "Amazing streak! You're on fire."
            }
        }()

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text("Encouragement")
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .accessibilityIdentifier("encouragementCard")
    }

    // MARK: - Helpers

    /// Computes consecutive-day streak ending today.
    /// A day counts if there is at least one task on that day.
    private func currentFocusStreak(tasks: [PomodoroTaskModel]) -> Int {
        guard !tasks.isEmpty else { return 0 }

        let byDay: Set<Date> = Set(tasks.map { Calendar.current.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: Date())

        while byDay.contains(cursor) {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = Calendar.current.startOfDay(for: prev)
        }
        return streak
    }
}

#Preview {
    ProfileView()
        .environmentObject(DataManager())
        .environmentObject(ProfileStore())
}

// Additional notes:
// Consider moving timer-driven tab changes (if any) behind an explicit user action
// or ensuring selection changes are not triggered by timer state updates.

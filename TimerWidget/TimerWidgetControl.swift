//CREATED  BY: nanthi13 ON 19/06/2026

import AppIntents
import SwiftUI
import WidgetKit
import ActivityKit

@available(iOS 17.0, *)
struct TimerWidgetControl: ControlWidget {
    static let kind: String = "no.ntnu.idata.arunanthi.FocusTracker.TimerWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

@available(iOS 17.0, *)
extension TimerWidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            TimerWidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            // Reflect current Live Activity state (if any).
            let activities = Activity<TimerWidgetAttributes>.activities
            let isRunning: Bool = {
                guard let activity = activities.first else { return false }
                let state = activity.content.state
                if state.isPaused { return false }
                if let end = state.endDate {
                    return end > Date()
                }
                return false
            }()
            return TimerWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

@available(iOS 17.0, *)
struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Name Configuration"

    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
}

@available(iOS 17.0, *)
struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    @Parameter(title: "Timer Name")
    var name: String

    @Parameter(title: "Timer is running")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        // Toggle semantics:
        // - If no activity: start a new focus session (15s default) and set running.
        // - If activity exists and running: pause it (capture remainingSeconds, clear endDate, set isPaused).
        // - If activity exists and paused: resume it (set endDate = now + remainingSeconds, isPaused = false).
        let defaultDuration: Int = 15

        if var existing = Activity<TimerWidgetAttributes>.activities.first {
            let state = existing.content.state

            if state.isPaused {
                // Resume: set a new end date based on remainingSeconds.
                let newEnd = Date().addingTimeInterval(TimeInterval(state.remainingSeconds))
                let newState = TimerWidgetAttributes.ContentState(
                    endDate: newEnd,
                    sessionType: state.sessionType,
                    isPaused: false,
                    remainingSeconds: state.remainingSeconds
                )
                await existing.update(ActivityContent(state: newState, staleDate: nil))
            } else {
                // Running -> Pause: compute remainingSeconds from endDate, clear endDate, set isPaused = true.
                let remaining: Int
                if let end = state.endDate {
                    remaining = max(0, Int(end.timeIntervalSinceNow))
                } else {
                    remaining = max(0, state.remainingSeconds)
                }
                let newState = TimerWidgetAttributes.ContentState(
                    endDate: nil,
                    sessionType: state.sessionType,
                    isPaused: true,
                    remainingSeconds: remaining
                )
                await existing.update(ActivityContent(state: newState, staleDate: nil))
            }
        } else {
            // No activity exists: start a new focus session with 15-second default.
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                // If Live Activities are not enabled, just return.
                return .result()
            }

            let attributes = TimerWidgetAttributes(sessionId: UUID())
            let end = Date().addingTimeInterval(TimeInterval(defaultDuration))
            let state = TimerWidgetAttributes.ContentState(
                endDate: end,
                sessionType: .focusTime,
                isPaused: false,
                remainingSeconds: defaultDuration
            )
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(
                        state: state,
                        staleDate: nil
                    )
                )
            } catch {
                // Silently ignore for control; app can log if needed.
            }
        }

        // Refresh the control so UI reflects the latest state.
        WidgetCenter.shared.reloadTimelines(ofKind: TimerWidgetControl.kind)
        return .result()
    }
}

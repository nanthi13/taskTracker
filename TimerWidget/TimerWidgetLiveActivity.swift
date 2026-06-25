//CREATED  BY: nanthi13 ON 19/06/2026

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
private struct CountdownView: View {
    let endDate: Date?
    let isPaused: Bool
    let remainingSeconds: Int
    
    private func format(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPaused ? "pause.fill" : "timer")
            if isPaused {
                Text(format(remainingSeconds))
                    .monospacedDigit()
            } else if let end = endDate {
                Text(end, style: .timer)
                    .monospacedDigit()
            } else {
                // Fallback if no endDate provided
                Text(format(remainingSeconds))
                    .monospacedDigit()
            }
        }
    }
}

@available(iOS 16.1, *)
struct TimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.state.sessionType == .focusTime ? "Focus Time" : "Break Time")
                    .font(.headline)
                CountdownView(
                    endDate: context.state.endDate,
                    isPaused: context.state.isPaused,
                    remainingSeconds: context.state.remainingSeconds
                )
                .font(.title2.weight(.semibold))

                // Controls row using deep links
                HStack(spacing: 16) {
                    Link(destination: URL(string: "focus-tracker://toggle")!) {
                        HStack {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .font(.title3)
                            Text(context.state.isPaused ? "Resume" : "Pause")
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Link(destination: URL(string: "focus-tracker://reset")!) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                            Text("Reset")
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.sessionType == .focusTime ? "brain.head.profile" : "cup.and.saucer.fill")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CountdownView(
                        endDate: context.state.endDate,
                        isPaused: context.state.isPaused,
                        remainingSeconds: context.state.remainingSeconds
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        Link(destination: URL(string: "focus-tracker://toggle")!) {
                            HStack {
                                Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                Text(context.state.isPaused ? "Resume" : "Pause")
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Link(destination: URL(string: "focus-tracker://reset")!) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } compactLeading: {
                Link(destination: URL(string: "focus-tracker://toggle")!) {
                    Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                }
            } compactTrailing: {
                Link(destination: URL(string: "focus-tracker://reset")!) {
                    Image(systemName: "arrow.counterclockwise")
                }
            } minimal: {
                Link(destination: URL(string: "focus-tracker://toggle")!) {
                    Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                }
            }
            .widgetURL(URL(string: "focus-tracker://live-activity"))
            .keylineTint(Color.red)
        }
    }
}

@available(iOS 16.1, *)
extension TimerWidgetAttributes {
    fileprivate static var preview: TimerWidgetAttributes {
        TimerWidgetAttributes(sessionId: UUID())
    }
}

@available(iOS 16.1, *)
extension TimerWidgetAttributes.ContentState {
    fileprivate static var smiley: TimerWidgetAttributes.ContentState {
        TimerWidgetAttributes.ContentState(
            endDate: .now.addingTimeInterval(25 * 60),
            sessionType: .focusTime,
            isPaused: false,
            remainingSeconds: 25 * 60
        )
     }
     
     fileprivate static var starEyes: TimerWidgetAttributes.ContentState {
         TimerWidgetAttributes.ContentState(
            endDate: nil,
            sessionType: .breakTime,
            isPaused: true,
            remainingSeconds: 5 * 60
         )
     }
}

@available(iOS 16.1, *)
#Preview("Notification", as: .content, using: TimerWidgetAttributes.preview) {
   TimerWidgetLiveActivity()
} contentStates: {
    TimerWidgetAttributes.ContentState.smiley
    TimerWidgetAttributes.ContentState.starEyes
}

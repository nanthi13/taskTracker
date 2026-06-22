//CREATED  BY: nanthi13 ON 19/06/2026

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
private struct CountdownView: View {
    let endDate: Date
    let isPaused: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPaused ? "pause.fill" : "timer")
            Text(endDate, style: .timer)
                .monospacedDigit()
        }
    }
}

@available(iOS 16.1, *)
struct TimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in
            // Lock screen / banner UI
            VStack(alignment: .leading, spacing: 8) {
                Text(context.state.sessionType == .focusTime ? "Focus Time" : "Break Time")
                    .font(.headline)
                CountdownView(endDate: context.state.endDate, isPaused: context.state.isPaused)
                    .font(.title2.weight(.semibold))
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
                    CountdownView(endDate: context.state.endDate, isPaused: context.state.isPaused)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.state.sessionType == .focusTime ? "Stay focused" : "Take a breather")
                            .font(.subheadline)
                        Text(context.state.endDate, style: .time)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                Image(systemName: context.state.sessionType == .focusTime ? "timer" : "cup.and.saucer")
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
            } minimal: {
                Text(context.state.endDate, style: .timer)
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
            isPaused: false
        )
     }
     
     fileprivate static var starEyes: TimerWidgetAttributes.ContentState {
         TimerWidgetAttributes.ContentState(
            endDate: .now.addingTimeInterval(5 * 60),
            sessionType: .breakTime,
            isPaused: false
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

//CREATED  BY: nanthi13 ON 19/06/2026

import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<TimerWidgetAttributes>?
    
    func startLiveActivity(endDate: Date, type: SessionType) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        let attributes = TimerWidgetAttributes(sessionId: UUID())
        let state = TimerWidgetAttributes.ContentState(
            endDate: endDate,
            sessionType: type,
            isPaused: false
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: state,
                    staleDate: nil
                )
            )
        } catch {
            print("Failed to start Live Activity:", error)
        }
    }
    
    func update(endDate: Date? = nil, isPaused: Bool? = nil, type: SessionType? = nil) async {
        guard let activity = currentActivity else { return }
        let current = activity.content.state
        let newState = TimerWidgetAttributes.ContentState(
            endDate: endDate ?? current.endDate,
            sessionType: type ?? current.sessionType,
            isPaused: isPaused ?? current.isPaused
        )
        await activity.update(ActivityContent(state: newState, staleDate: nil))
    }
    
    func end() async {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        
        // Provide a final content state and a concrete dismissal policy.
        let finalState = activity.content.state
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
    }
}

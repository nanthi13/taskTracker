//CREATED  BY: nanthi13 ON 22/06/2026
// Target Membership: FocusTracker (app) + TimerWidgetExtension (widget)

import AppIntents

struct TogglePauseResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Pause/Resume Timer"

    // No-op here so the widget can compile without app-only types.
    func perform() async throws -> some IntentResult {
//         unable to find timercontrolcenter
//        await TimerControlCenter.shared.togglePauseResume()
        .result()
    }
}

struct ResetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    
    // No-op here so the widget can compile without app-only types.
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            // unable to find tinmercontrolcenter in widget extension so calling reset on shared instance
            // still running dynamic island independent of app, using a different timer.
            //            TimerControlCenter.shared.reset()
        
            .result()
        }
    }
}

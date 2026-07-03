//// Target Membership: FocusTracker (app) ONLY
//
//import AppIntents
//
//extension TogglePauseResumeTimerIntent {
//    func perform() async throws -> some IntentResult {
//        await TimerControlCenter.shared.togglePauseResume()
//        return .result()
//    }
//}
//
//extension ResetTimerIntent {
//    func perform() async throws -> some IntentResult {
//        await MainActor.run {
//            TimerControlCenter.shared.reset()
//        }
//        return .result()
//    }
//}

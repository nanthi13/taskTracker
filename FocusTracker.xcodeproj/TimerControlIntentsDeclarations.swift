import AppIntents

struct TogglePauseResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Pause/Resume Timer"
    func perform() async throws -> some IntentResult { .result() }
}

struct ResetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    func perform() async throws -> some IntentResult { .result() }
}

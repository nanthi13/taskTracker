// TimerControlCenter.swift (app target only)
@MainActor
final class TimerControlCenter {
    static let shared = TimerControlCenter()
    private init() {}
    weak var timerManager: TimerManager?

    func register(_ manager: TimerManager) { timerManager = manager }

    func togglePauseResume() async {
        guard let tm = timerManager else { return }
        switch tm.state {
        case .running: tm.pauseTimer()
        case .paused: tm.resumeTimer()
        case .idle: await tm.startTimer()
        }
    }

    func reset() { timerManager?.resetTimer() }
}

//CREATED  BY: nanthi13 ON 22/06/2026

import Foundation
import ActivityKit
import WidgetKit

public enum SessionType: String, Codable, Hashable, Sendable {
    case focusTime
    case breakTime
}

public struct TimerWidgetAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endDate: Date?
        public var sessionType: SessionType
        public var isPaused: Bool
        public var remainingSeconds: Int

        public init(endDate: Date?, sessionType: SessionType, isPaused: Bool, remainingSeconds: Int) {
            self.endDate = endDate
            self.sessionType = sessionType
            self.isPaused = isPaused
            self.remainingSeconds = remainingSeconds
        }
    }

    public var sessionId: UUID

    public init(sessionId: UUID) {
        self.sessionId = sessionId
    }
}

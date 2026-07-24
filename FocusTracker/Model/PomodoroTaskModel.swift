//CREATED  BY: nanthi13 ON 20/01/2026
// Simple data model for tasks.
import Foundation
import SwiftUI

// Equatable conformance allows us to compare tasks for equality, which is useful for updating the UI when tasks change. However may interfere with UUID.
struct PomodoroTaskModel: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    let duration: Int
    let date: Date
}

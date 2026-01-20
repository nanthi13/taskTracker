//CREATED  BY: nanthi13 ON 20/01/2026
// Simple data model for tasks.
import Foundation
import SwiftUI

struct PomodoroTaskModel: Identifiable, Codable {
    var id = UUID()
    var name: String
    let duration: Int
    let date: Date
}

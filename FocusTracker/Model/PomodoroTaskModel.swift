//CREATED  BY: nanthi13ON 20/01/2026

import Foundation
import SwiftUI

struct PomodoroTaskModel: Identifiable, Codable {
    var id = UUID()
    var name: String
    let duration: Int
    let date: Date    
}

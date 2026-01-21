//CREATED  BY: nanthi13 ON 21/01/2026

import Testing
@testable import FocusTracker
import Foundation

struct PomodoroTaskModelTests {

    @Test func initialization_setsporpertiesCorrectly() {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let date = Date()
        let task = PomodoroTaskModel(
            name: "Reading",
            duration: 25,
            date: date
        )
        
        #expect(task.name == "Reading")
        #expect(task.duration == 25)
        #expect(task.date == date)
        #expect(task.id != UUID())
    }
    
    @Test
    func ids_areUnique() {
        let task1 = PomodoroTaskModel(name: "Task1", duration: 30, date: Date())
        let task2 = PomodoroTaskModel(name: "Task2", duration: 40, date: Date())
        
        #expect(task1.id != task2.id)
    }
    
    @Test @MainActor
    func codable_roundTrip() throws {
        let task = PomodoroTaskModel(name: "Writing", duration: 20, date: Date())
        
        let data = try JSONEncoder().encode(task)
        let decodedTask = try JSONDecoder().decode(PomodoroTaskModel.self, from: data)
        
        #expect(decodedTask.id == task.id)
        #expect(decodedTask.name == task.name)
        #expect(decodedTask.duration == task.duration)
        #expect(decodedTask.date == task.date)
        
        
        
    }

}

// User.swift
import Foundation

struct User: Codable, Equatable, Identifiable {
    var id: UUID
    var displayName: String

    init(id: UUID = UUID(), displayName: String = "Your Name") {
        self.id = id
        self.displayName = displayName
    }
}

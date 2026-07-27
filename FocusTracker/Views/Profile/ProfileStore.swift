// ProfileStore.swift
import Foundation
import SwiftUI

@MainActor
final class ProfileStore: ObservableObject {

    @Published var user: User {
        didSet { save() }
    }

    private let storageKey = "profile_user_v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            self.user = decoded
        } else {
            self.user = User()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

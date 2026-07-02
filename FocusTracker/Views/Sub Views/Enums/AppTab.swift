// Created by: nanthi13 on 29/01/2026

import Foundation

/// Application tabs for the main TabView.
/// - testing: Development-only tab to seed mock data and inspect charts/history.
enum AppTab: Hashable {
    case home
    case charts
    case history
    case profile
    case testing
}


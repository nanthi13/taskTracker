//CREATED  BY: nanthi13ON 20/01/2026

import SwiftUI

@main
struct FocusTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    Task { @MainActor in
                        switch url.host {
                        case "toggle":
                            await TimerControlCenter.shared.togglePauseResume()
                        case "reset":
                            TimerControlCenter.shared.reset()
                        default:
                            break
                        }
                    }
                }
        }
    }
}

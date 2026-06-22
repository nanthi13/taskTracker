//CREATED  BY: nanthi13 ON 19/06/2026

import WidgetKit
import SwiftUI

@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        if #available(iOS 17.0, *) {
            TimerWidgetControl()
        }
        if #available(iOS 16.1, *) {
            TimerWidgetLiveActivity()
        }
    }
}

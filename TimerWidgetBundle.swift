// In TimerWidgetBundle.swift
import WidgetKit
import SwiftUI
import ActivityKit


struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        TimerWidgetControl()
        if #available(iOS 16.1, *) {
            TimerWidgetLiveActivity()
        }
    }
}

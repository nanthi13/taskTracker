//CREATED  BY: nanthi13ON 20/01/2026

import Foundation
import SwiftUI

struct PomodoroButtonStyle: ButtonStyle {
    var color: Color
    //var color = Color(.gray)
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .frame(width: 100, height: 50)
                .background(.gray.opacity(0.10))
                .foregroundColor(color)
                .cornerRadius(0)
                .opacity(configuration.isPressed ? 0.7 : 1)
                //.glassEffect(.regular.tint(.gray))
        } else {
            // Fallback on earlier versions
            configuration.label
                .frame(width: 100, height: 50)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(8)
                .opacity(configuration.isPressed ? 0.7 : 1)
            
        }
    }
}

//struct PomodoroButtonStyle: ButtonStyle {
//    let color: Color
//
//    func makeBody(configuration: Configuration) -> some View {
//        if #available (iOS 26.0, *) {
//            configuration.label
//                .font(.system(size: 28, weight: .semibold))
//                .foregroundStyle(color)
//                .frame(width: 56, height: 56)
//                .background {
//                    Circle()
//                        .fill(color.opacity(0.15))
//                }
//                .overlay {
//                    Circle()
//                        .stroke(color.opacity(0.35), lineWidth: 1)
//                }
//                .scaleEffect(configuration.isPressed ? 0.92 : 1)
//                .opacity(configuration.isPressed ? 0.7 : 1)
//                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
//        } else {
//            configuration.label
//                .font(.system(size: 24, weight: .semibold))
//                .foregroundStyle(.white)
//                .frame(width: 60, height: 60)
//                .background(color.gradient)
//                .clipShape(Circle())
//                .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
//                .opacity(configuration.isPressed ? 0.8 : 1.0)
//                .animation(
//                    .easeOut(duration: 0.15),
//                    value: configuration.isPressed
//                )
//        }
//    }
//}


//
//  ToastModifier.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/6.
//

import Foundation
import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    
    let duration: TimeInterval
    let alignment: Alignment
    
    func body(content: Content) -> some View {
        content.overlay(alignment: alignment) {
            if let text = message {
                Text(text)
                    .lineLimit(2)
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
                    .containerShape(.capsule)
                    .shadow(radius: 36)
                    .transition(.opacity.combined(with: .scale))
                    .task {
                        try! await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                        withAnimation {
                            message = nil
                        }
                    }
            } else {
                EmptyView()
            }
        }
    }
}

extension View {
    /// Show toast
    /// - Parameters:
    ///   - message: The message of toast
    ///   - duration: The duration of toast
    func toast(message: Binding<String?>, duration: TimeInterval = 1.5) -> some View {
        self.modifier(ToastModifier(message: message, duration: duration, alignment: .center))
    }
}

//
//  ViewDidLoadModifier.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/3.
//

import SwiftUI

struct ViewDidLoadModifier: ViewModifier {
    @State private var isFirst = true
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content.task {
            if isFirst {
                await action()
                isFirst = false
            }
        }
    }
}

extension View {
    func onLoad(_ action: @escaping () async -> Void) -> some View {
        self.modifier(ViewDidLoadModifier(action: action))
    }
}

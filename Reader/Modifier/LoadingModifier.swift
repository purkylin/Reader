//
//  LoadingModifier.swift
//  Reader
//
//  Created by Purkylin King on 2023/10/20.
//

import SwiftUI

struct LoadingModifier: ViewModifier {
    @Binding var isLoading: Bool
    
    func body(content: Content) -> some View {
        content.overlay {
            if isLoading {
                ProgressView().progressViewStyle(.circular).controlSize(.large)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Binding<Bool>) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

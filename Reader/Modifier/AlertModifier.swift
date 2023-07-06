//
//  AlertModifier.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/6.
//

import SwiftUI

struct AlertError: LocalizedError, ExpressibleByStringLiteral {
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    init(_ error: any Error) {
        self.text = error.localizedDescription
    }
    
    init(stringLiteral value: StringLiteralType) {
        self.text = value
    }
    
    var errorDescription: String? {
        return text
    }
}

extension View {
    func alert<E: LocalizedError>(error: Binding<E?>) -> some View {
        self.modifier(InternalErrorAlert(error: error))
    }
}

private struct InternalErrorAlert<E: LocalizedError>: ViewModifier {
    @Binding var error: E?
    
    private var hasError: Binding<Bool> {
        Binding {
            error != nil
        } set: { _ in
            error = nil
        }
    }
    
    func body(content: Content) -> some View {
        return content.alert(isPresented: hasError, error: error) { }
    }
}

//
//  Toast.swift
//  Reader
//
//  Created by Purkylin King on 2023/10/19.
//

import SwiftUI

/// SwiftUI Toast
struct Toast: View {
    @Binding var entry: ToastEntry?
    @State private var shouldShow: Bool = false
    
    var body: some View {
        return VStack {
            if let entry, shouldShow {
                HStack {
                    Image(systemName: entry.style.icon).font(.title)
                        .foregroundStyle(entry.style.color)
                    Text(entry.msg)
                }
                .ignoresSafeArea()
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .compositingGroup()
                .shadow(color: .black.opacity(0.1), radius: 5)
                .padding(.horizontal)
                .transition(.move(edge: entry.position == .top ? .top : .bottom).animation(.spring.speed(4)).combined(with: .opacity))
                .sensoryFeedback(entry.style.feedback, trigger: shouldShow)
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: entry?.position == .top ? .top : .bottom)
        .onChange(of: entry) {
            if let entry {
                withAnimation {
                    shouldShow = true
                } completion: {
                    autoDismiss(delay: entry.duration)
                }
            }
        }
    }
    
    private func autoDismiss(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation {
                shouldShow = false
            } completion: {
                entry = nil
            }
        }
    }
}

struct ToastEntry {
    let style: Self.Style
    let msg: String
    let position: Self.Position
    let duration: TimeInterval
    
    init(style: Self.Style, msg: String, position: Self.Position = .bottom, duration: TimeInterval = 2.0) {
        self.style = style
        self.msg = msg
        self.position = position
        self.duration = duration
    }
}

extension ToastEntry {
    enum Style {
        case success
        case error
        case warning
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle"
            case .error:
                return "x.circle"
            case .warning:
                return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .warning:
                return .yellow
            }
        }
        
        var feedback: SensoryFeedback {
            switch self {
            case .success:
                return .success
            case .error:
                return .error
            case .warning:
                return .warning
            }
        }
    }
}

extension ToastEntry {
    enum Position {
        case top
        case bottom
    }
}

extension ToastEntry: Equatable { }

struct ToastModifier: ViewModifier {
    @Binding var entry: ToastEntry?
    
    func body(content: Content) -> some View {
        content.overlay {
            Toast(entry: $entry)
        }
    }
}

extension View {
    func toast(entry: Binding<ToastEntry?>) -> some View {
        self.modifier(ToastModifier(entry: entry))
    }
}

struct TestToast: View {
    @State var entry: ToastEntry?
    
    var body: some View {
        VStack {
            Button("Show") {
                entry = ToastEntry(style: .success, msg: "Happy new year!", position: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toast(entry: $entry)
    }
}

#Preview {
    TestToast()
}

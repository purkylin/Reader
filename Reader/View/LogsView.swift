//
//  LogsView.swift
//  Reader
//
//  Created by Purkylin King on 2023/10/23.
//

import SwiftUI
import OSLog

struct LogsView: View {
    @State private var output = ""
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            TextEditor(text: .constant(output))
                .padding()
                .navigationTitle("Logs")
                .toolbar {
                    Button("Done") {
                        dismiss()
                    }
                }
                .loading($isLoading)
                .task {
                    isLoading = true
                    Task {
                        let result = export()
                        await MainActor.run {
                            isLoading = false
                            self.output = result
                        }
                    }
                }
        }

    }
    
    private func export() -> String {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceLatestBoot: 1)
            let entries = try store.getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
                .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
            return entries.joined(separator: "\n")
        } catch {
            return error.localizedDescription
        }
    }
}

//
//  SettingsView.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/4.
//

import SwiftUI
import SwiftData
import TipKit

struct SettingsView: View, Logging {
    @State private var showImport = false
    @State private var showExport = false
    @State private var document: OpmlDocument?
    
    @AppStorage("EnabledAutoClean") var enabledAutoClean = false
    
    @Environment(Store.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $enabledAutoClean) {
                        Label("Auto clearn old articles", systemImage: "paintbrush")
                    }
                }
                
                Section {
                    Button(action: exportAction) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Button(action: importAction) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(.plain)
                
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileExporter(isPresented: $showExport, document: document, contentType: OpmlDocument.pubType, defaultFilename: "my-rss", onCompletion: { result in
                //
            })
            .fileImporter(isPresented: $showImport, allowedContentTypes: [OpmlDocument.pubType]) { result in
                switch result {
                case .success(let url):
                    Task {
                        await importOPML(url)
                    }
                case .failure(let error):
                    logger.error("import failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func exportAction() {
        showExport = true
        do {
            let feeds = try Feed.getAll(in: modelContext)
            document = OpmlDocument(feeds: feeds)
        } catch {
            logger.error("export failed: \(error.localizedDescription)")
        }
    }
    
    private func importAction() {
        showImport = true
    }
    
    private func importOPML(_ url: URL) async {
        do {
            _ = url.startAccessingSecurityScopedResource()
            let data = try Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()
            
            let obj = try OPMLParser.parse(data: data)
            let items = obj.sections.flatMap { $0.items }
            
            for item in items {
                try await store.addFeed(url: item.xmlUrl, in: modelContext)
            }
            
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}

extension Feed {
    static func getAll(in context: ModelContext) throws -> [Feed] {
        return try context.fetch(FetchDescriptor<Feed>())
    }
}

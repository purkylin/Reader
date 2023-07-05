//
//  SettingsView.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/4.
//

import SwiftUI

struct SettingsView: View, Logging {
    @State private var showImport = false
    @State private var showExport = false
    @State private var document: OpmlDocument?
    
    @Environment(RSSStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Mark all Read") {
                        
                    }
                    
                    Button("Clean up old articles") {
                        
                    }
                    
                    Button(action: exportAction) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Button(action: importAction) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            
            .fileExporter(isPresented: $showExport, document: document, contentType: OpmlDocument.pubType, defaultFilename: "My-Sub", onCompletion: { result in
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

    }
    
    private func importAction() {
        showImport = true
    }
    
    private func importOPML(_ url: URL) async {
        do {
            let data = try Data(contentsOf: url)
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

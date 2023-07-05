//
//  OPMLDocument.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/4.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct OpmlDocument: FileDocument {
    let feeds: [Feed]
    
    static var readableContentTypes: [UTType] {
        [pubType]
    }
    
    static var pubType: UTType {
        UTType(filenameExtension: "opml", conformingTo: .xml)!
    }
    
    init(configuration: ReadConfiguration) throws {
        self.feeds = []
    }
    
    init(feeds: [Feed]) {
        self.feeds = feeds
    }
    
    @MainActor
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let payload = OPMLExporter.OPMLString(title: "subscription", feeds: feeds)
        let fileName = "subscription.opml"
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try payload.write(to: tempFile, atomically: true, encoding: .utf8)
        return try FileWrapper(url: tempFile)
    }
}

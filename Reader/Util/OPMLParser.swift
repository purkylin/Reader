//
//  OPMLParser.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/4.
//

import Foundation
import SwiftyXMLParser

struct OPMLParser {
    typealias Item = WebOPML.Item
    typealias Section = WebOPML.Section
    
    static func parse(data: Data) throws -> WebOPML {
        let xml = XML.parse(data)
        
        if case .failure(XMLError.interruptedParseError) = xml {
            throw RssParseError.invalidXml
        }
        
        let root = xml.opml
        guard let title = root["head", "title"].text else {
            throw RssParseError.invalidFormat
        }
        
        let sections = root["body", "outline"].compactMap { parseSection($0) }
        if sections.isEmpty {
            throw RssParseError.empty
        }
        
        return WebOPML(title: title, sections: sections)
    }
    
    private static func parseSection(_ node: XML.Accessor) -> Section? {
        let title = node.attributes["text"]
        let text = node.attributes["title"]
        
        let items = node.outline.compactMap { parseItem($0) }
        return Section(text: text, title: title, items: items)
    }
    
    private static func parseItem(_ node: XML.Accessor) -> Item? {
        guard let htmlUrl = node.attributes["htmlUrl"],
              let xmlUrl = node.attributes["xmlUrl"],
              let title = node.attributes["text"]
              else {
            return nil
        }
        
        let type = node.attributes["type"] ?? "rss"
        
        guard type == "rss" else { return nil }
        guard let hUrl = URL(string: htmlUrl),
                let xUrl = URL(string: xmlUrl) else {
            return nil
        }
        
        return Item(htmlUrl: hUrl, xmlUrl: xUrl, title: title)
    }
}

struct WebOPML {
    let title: String
    let sections: [Section]
    
    struct Item {
        let htmlUrl: URL
        let xmlUrl: URL
        let title: String
    }
    
    struct Section {
        let text: String?
        let title: String?
        let items: [Item]
    }
    
    static func parse(data: Data) throws -> WebOPML {
        return try OPMLParser.parse(data: data)
    }
}

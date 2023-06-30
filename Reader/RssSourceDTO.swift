//
//  RssSourceDTO.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftyXMLParser

struct RssSourceDTO {
    let title: String
    let link: URL
    let desc: String
    let logo: URL?
    let items: [Item]
    
    struct Item {
        let title: String
        let link: URL
        let content: String?
        let pubDate: Date
        let author: String?
    }
    
    static func parse(data: Data) throws -> RssSourceDTO {
        let xml = XML.parse(data)
        
        if case .failure(XMLError.interruptedParseError) = xml {
            throw RssParseError.invalidXml
        }
        
        if xml.feed.element != nil {
            return try AtomFeedParser.parse(data: data)
        } else {
            return try RssFeedParser.parse(data: data)
        }
    }
}

enum RssParseError: Swift.Error, LocalizedError {
    case invalidFormat
    case empty
    case invalidXml
    case notSupportedType
    case invalidDate
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid format"
        case .empty:
            return "The feeds is empty"
        case .invalidXml:
            return "Invalid xml file"
        case .notSupportedType:
            return "The type is not supported"
        case .invalidDate:
            return "Invalid date format"
        }
    }
}

private class RssFeedParser {
    typealias Item = RssSourceDTO.Item
    
    private static var formatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        fmt.locale = Locale(identifier: "en_US")
        return fmt
    }()
    
    static func parse(data: Data) throws -> RssSourceDTO {
        let xml = XML.parse(data)
        
        if case .failure(XMLError.interruptedParseError) = xml {
            throw RssParseError.invalidXml
        }
        
        let channel = xml.rss.channel
        
        guard let title = channel.title.text,
                let link = channel.link.text,
                let url = URL(string: link)
                 else {
            throw RssParseError.invalidFormat
        }
        
        let desc = channel["description"].text ?? ""
        let logo = channel["image", "url"].url
        
        let feeds = try parseItems(at: channel)
        if feeds.isEmpty {
            throw RssParseError.empty
        }
        
        return RssSourceDTO(title: title, link: url, desc: desc, logo: logo, items: feeds)
    }
    
    private static func getDate(from string: String) -> Date? {
        if let date = Self.formatter.date(from: string) {
            return date
        }
        
        // Compatiable
        if let date = try? Date(string, strategy: .iso8601.year().month().day().dateTimeSeparator(.space).time(includingFractionalSeconds: false)) {
            return date
        }
        
        return nil
    }
    
    private static func parseItems(at node: XML.Accessor) throws -> [Item] {
        var result = [RssSourceDTO.Item]()
        
        for item in node.item {
            let strDate = item.pubDate.getText() ?? ""
            
            guard let date = getDate(from: strDate) else {
                throw RssParseError.invalidDate
            }
            
            guard let title = item.title.getText(),
                  let link = item.link.getText(),
                  let url = URL(string: link) else {
                continue
            }
            
            let desc = node["description"].getText()
            let feed = Item(title: title, link: url, content: desc, pubDate: date, author: item.author.text)
            result.append(feed)
        }
        
        return result
    }
}

private class AtomFeedParser {
    typealias Item = RssSourceDTO.Item
    
    static func parse(data: Data) throws -> RssSourceDTO {
        let xml = XML.parse(data)
        
        if case .failure(XMLError.interruptedParseError) = xml {
            throw RssParseError.invalidXml
        }
        
        let root = xml.feed
        
        guard let title = root.title.text,
              let link = root.link.last.attributes["href"],
                let url = URL(string: link),
                let desc = root.subtitle.text else {
            throw RssParseError.invalidFormat
        }
        
        let logo = root["logo"].url // or icon
        
        let feeds = parseItems(at: root)
        if feeds.isEmpty {
            throw RssParseError.empty
        }
        
        return RssSourceDTO(title: title, link: url, desc: desc, logo: logo, items: feeds)
    }
    
    private static func parseItems(at node: XML.Accessor) -> [Item] {
        var result = [RssSourceDTO.Item]()
        
        for item in node.entry {
            guard let strDate = item.updated.text,
                  let date = try? Date(strDate, strategy: .iso8601),
                  let title = item.title.text,
                  let link = item.link.attributes["href"],
                  let url = URL(string: link) else {
                continue
            }
            
            let desc = node.summuary.getText()
            let feed = Item(title: title, link: url, content: desc, pubDate: date, author: item.author.text)
            result.append(feed)
        }
        
        return result
    }
}


struct RSSOpml {
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
    
    static func parse(data: Data) throws -> RSSOpml {
        return try OpmlParser.parse(data: data)
    }
}

private class OpmlParser {
    typealias Item = RSSOpml.Item
    typealias Section = RSSOpml.Section
    
    static func parse(data: Data) throws -> RSSOpml {
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
        
        return RSSOpml(title: title, sections: sections)
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
              let title = node.attributes["title"],
              let type = node.attributes["type"] else {
            return nil
        }
        
        guard type == "rss" else { return nil }
        guard let hUrl = URL(string: htmlUrl),
                let xUrl = URL(string: xmlUrl) else {
            return nil
        }
        
        return Item(htmlUrl: hUrl, xmlUrl: xUrl, title: title)
    }
}

extension RSSOpml: Identifiable {
    var id: String {
        title
    }
}

extension XML.Accessor {
    func getText() -> String? {
        if let text {
            return text
        }
        
        if let data = self.element?.CDATA, let text = String(data: data, encoding: .utf8) {
            return text
        }
        
        return nil
    }
}


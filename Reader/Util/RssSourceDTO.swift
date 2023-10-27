//
//  RssSourceDTO.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftyXMLParser

// TODO: Refactor
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

// [Specification](https://www.rssboard.org/rss-specification#sampleFiles)
private class RssFeedParser {
    typealias Item = RssSourceDTO.Item
    
    private static var formatter: DateFormatter = {
        // RFC 822
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
        
        guard let title = channel.title.getText(),
                let link = channel.link.getText(),
                let url = URL(string: link)
                 else {
            throw RssParseError.invalidFormat
        }
        
        let desc = channel["description"].getText() ?? ""
        let logo = channel["image", "url"].url
        // TODO: support lastBuildDate
        let defaultDate = channel["pubDate"].text.map(getDate(from:))?.map { $0 }
         
        let feeds = try parseItems(at: channel, defaultDate: defaultDate)
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
    
    private static func parseItems(at node: XML.Accessor, defaultDate: Date? = nil) throws -> [Item] {
        var result = [RssSourceDTO.Item]()
        
        for item in node.item {
            let strDate = item.pubDate.getText() ?? ""
            guard let date = getDate(from: strDate) ?? defaultDate else {
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

extension XML.Accessor {
    func getText() -> String? {
        if let text {
            return text
        }
        
        if let data = self.element?.CDATA, let text = String(data: data, encoding: .utf8) {
            return text.strip()
        }
        
        return nil
    }
}

extension String {
    func strip() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

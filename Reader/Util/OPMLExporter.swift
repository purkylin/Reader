//
//  OPMLExporter.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/4.
//

import Foundation

@MainActor struct OPMLExporter {

    static func OPMLString(title: String, feeds: [Feed]) -> String {

        let escapedTitle = title.escapingSpecialXmlCharacters
        let openingText =
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!-- OPML generated by Reader -->
            <opml version="1.1">
                <head>
                    <title>\(escapedTitle)</title>
                </head>
                <body>
            
            """

        let closingText =
            """
                </body>
            </opml>
            """

        let middleText = group(feeds: feeds)
        let opml = openingText + middleText + closingText
        return opml
    }
    
    private static func item(for feed: Feed) -> String {
        """
        <outline htmlUrl="\(feed.homepage)" xmlUrl="\(feed.url)" type="rss" text="\(feed.title)"/>
        """
    }
    
    private static func group(feeds: [Feed]) -> String {
        let indent = String(repeating: " ", count: 4)
        let content = feeds.map { String(repeating: indent, count: 2) + item(for: $0) }.joined(separator: "\n")
        
        return """
        \(indent)<outline text="" title="Default">
        \(content)
        \(indent)</outline>
        
        """
    }
}

extension String {
    fileprivate var escapingSpecialXmlCharacters: String {
        var escaped = String()

        for char in self {
            switch char {
                case "&":
                    escaped.append("&amp;")
                case "<":
                    escaped.append("&lt;")
                case ">":
                    escaped.append("&gt;")
                case "\"":
                    escaped.append("&quot;")
                default:
                    escaped.append(char)
            }
        }
        
        return escaped
    }
}

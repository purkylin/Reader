//
//  RssSource.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftData

@Model
class RssSource {
    @Attribute(.unique)
    let title: String
    @Attribute(.unique)
    let link: URL // site url
    let desc: String
    let logo: URL?
    let url: URL // subscript url
        
    @Relationship(.cascade)
    var items: [RssFeed]
    
    init(url: URL, title: String, link: URL, desc: String, logo: URL?, items: [RssFeed]) {
        self.url = url
        self.title = title
        self.link = link
        self.desc = desc
        self.logo = logo
        self.items = items
    }
}

@Model
class RssFeed {
    let title: String
    let link: URL
    let content: String?
    let pubDate: Date
    let author: String?
    
    var viewed = false
    
    @Relationship(inverse: \RssSource.items)
    var source: RssSource?
    
    init(title: String, link: URL, content: String?, pubDate: Date, author: String?) {
        self.title = title
        self.link = link
        self.content = content
        self.pubDate = pubDate
        self.author = author
    }
}

extension RssSource: Identifiable {
    var id: String { title }
}

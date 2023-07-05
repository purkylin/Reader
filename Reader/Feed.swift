//
//  RssSource.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftData

@Model
class Feed {
    @Attribute(.unique)
    let title: String
    @Attribute(.unique)
    let homepage: URL // site url
    let desc: String
    let logo: URL?
    let url: URL // subscript url
        
    @Relationship(.cascade)
    var articles: [Article]
    
    init(url: URL, title: String, homepage: URL, desc: String, logo: URL?, articles: [Article]) {
        self.url = url
        self.title = title
        self.homepage = homepage
        self.desc = desc
        self.logo = logo
        self.articles = articles
    }
    
    var icon: URL? {
        return logo ?? homepage.appending(component: "favicon.ico")
    }
}

@Model
class Article {
    let title: String
    let link: URL
    let content: String?
    let pubDate: Date
    let author: String?
    
    var viewed = false
    
    @Relationship(inverse: \Feed.articles)
    var feed: Feed?
    
    init(title: String, link: URL, content: String?, pubDate: Date, author: String?) {
        self.title = title
        self.link = link
        self.content = content
        self.pubDate = pubDate
        self.author = author
    }
}

extension Feed: Identifiable {
    var id: String { title }
}

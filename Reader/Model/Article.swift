//
//  Article.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/6.
//

import Foundation
import SwiftData

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

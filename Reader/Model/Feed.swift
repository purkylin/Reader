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
    var title: String
    let homepage: URL // site url
    let desc: String
    let logo: URL?
    @Attribute(.unique)
    let url: URL // subscript url
    
    // TODO: type: rss/atom
        
    @Relationship(deleteRule: .cascade)
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

extension Feed: Identifiable {
    var id: String { title }
}

extension Feed {
    static var all: FetchDescriptor<Feed>{
        FetchDescriptor()
    }
}

enum FeedType: String, Codable {
    case rss
    case atom
    case unknown
}

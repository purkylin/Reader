//
//  BackgroundActor.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/10.
//

import Foundation
import SwiftData
import OSLog

@ModelActor
actor BackgroundActor: Logging {

    func run(task: (ModelContext) -> Void) {
        task(modelContext)
    }
    
    /// Add feed
    func addFeed(url: URL, dto: RssSourceDTO) throws {
        let feed =  Feed(url: url, title: dto.title, homepage: dto.link, desc: dto.desc, logo: dto.logo, articles: [])
        modelContext.insert(feed)
        try updateFeed(feed, with: dto.items)
        try save()
    }
    
    func updateFeed(_ identifier: PersistentIdentifier, items: [RssSourceDTO.Item]) throws {
        let feed = modelContext.model(for: identifier) as! Feed
        try updateFeed(feed, with: items)
    }
    
    /// Update feed
    private func updateFeed(_ feed: Feed, with items: [RssSourceDTO.Item]) throws {
        let lastUdateTime = feed.lastUpdateTime() ?? Date(timeIntervalSince1970: 0)
        
        for item in items {
            if item.pubDate > lastUdateTime {
                let article = Article.article(from: item, in: modelContext)
                article.feed = feed
                modelContext.insert(article)
            }
        }
        
        try save()
    }
    
    private func save() throws {
        // autosaveEnabled is false for new context by hand
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
    /// Clean old articles
    func clean() async {
        let context = self.modelContext
        
        do {
            let threshold = 500
            let predicate = #Predicate<Feed> { $0.articles.count > threshold }
            let feeds = try context.fetch(FetchDescriptor(predicate: predicate))
            for feed in feeds {
                let filterTitle = feed.title
                let articlePredicate = #Predicate<Article> { $0.feed?.title == filterTitle }
                var desc = FetchDescriptor(predicate: articlePredicate, sortBy: [SortDescriptor(\.pubDate, order: .forward)])
                desc.fetchLimit = max(feed.articles.count - threshold, 0)
                let toDeleteArticles = try context.fetch(desc)
                for article in toDeleteArticles {
                    context.delete(article)
                }
                
                logger.info("clean old article for feed: \(feed.title) success")
            }
            
            try context.save()
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}

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
    
    func updateFeed(_ feed: Feed, items: [RssSourceDTO.Item]) {
        let lastUdateTime = feed.lastUpdateTime(in: modelContext) ?? Date(timeIntervalSince1970: 0)
        
        for item in items {
            if item.pubDate > lastUdateTime {
                let article = Article.article(from: item, in: modelContext)
                article.feed = feed
                modelContext.insert(article)
            }
        }
    }
    
    func clean() async {
        let context = self.modelContext
        
        do {
            let threshold = 1000
            let predicate = #Predicate<Feed> { $0.articles.count > threshold }
            let feeds = try context.fetch(FetchDescriptor(predicate: predicate))
            for feed in feeds {
                let filterTitle = feed.title
                let articlePredicate = #Predicate<Article> { $0.feed?.title == filterTitle }
                var desc = FetchDescriptor(predicate: articlePredicate, sortBy: [SortDescriptor(\.pubDate, order: .forward)])
                desc.fetchLimit = max(feeds.count - threshold, 0)
                let toDeleteArticles = try context.fetch(desc)
                for article in toDeleteArticles {
                    context.delete(article)
                }
                
                try context.save()
                logger.info("clean old article for feed: \(feed.title) success")
            }
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}

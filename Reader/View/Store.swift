//
//  Store.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/4.
//

import Foundation
import SwiftData
import Observation

@Observable
class Store: Logging {
    // 15 mins
    private let mininalRefeshInterval: TimeInterval = 15 * 60

    var lastUpdateTime: Date? = nil
    
    @MainActor
    func addFeed(url: URL, in context: ModelContext) async throws {
        let dto = try await fetchWebFeed(url: url)
        let newFeed =  Feed(url: url, title: dto.title, homepage: dto.link, desc: dto.desc, logo: dto.logo, articles: [])
        context.insert(newFeed)
        try context.save()
        try await newFeed.updateArticles(dto.items)
    }
    
    private func fetchWebFeed(url: URL) async throws -> RssSourceDTO {
        let (data, _) = try await URLSession.shared.data(from: url)
        let source = try RssSourceDTO.parse(data: data)
        return source
    }
    
    func refresh(feeds: [Feed], force: Bool = false) async {
        if !force {
            if let time = lastUpdateTime, Date().timeIntervalSince(time) < mininalRefeshInterval {
                return
            }
        }
    
        logger.trace("refreshing...")
    
        for item in feeds {
            do {
                try await updateFeed(item)
                self.lastUpdateTime = .now
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
    
    private func updateFeed(_ feed: Feed) async throws {
        let dto = try await fetchWebFeed(url: feed.url)
        try await feed.updateArticles(dto.items)
    }
    
    func clean() async {
        await databaseActor.run { context in
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
}

extension Feed {
    static func getFeed(by name: String, in context: ModelContext) throws -> Feed? {
        let predicate = #Predicate<Feed> { $0.title == name }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
    }
    
    @MainActor
    func lastUpdateTime() -> Date? {
        guard let context = self.context else { fatalError("Can't get context") }
        let name = self.title
        let predicate = #Predicate<Article> { $0.feed?.title == name }
        return try? context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.pubDate, order: .reverse)])).first?.pubDate
    }
    
    func unreadCount() -> Int {
        guard let context = self.context else {
            fatalError("Get context failed")
        }
        
        let name = self.title
        let predicate = #Predicate<Article> { $0.feed?.title == name && $0.viewed == false }
        return try! context.fetch(FetchDescriptor(predicate: predicate)).count
    }
    
    @MainActor
    func updateArticles(_ items: [RssSourceDTO.Item]) async throws {
        let lastUdateTime = self.lastUpdateTime() ?? Date(timeIntervalSince1970: 0)
        
        for item in items {
            if item.pubDate > lastUdateTime {
                let article = Article(from: item)
                article.feed = self
                context?.insert(article)
            }
        }
    }
}

extension Article {
    convenience init(from dto: RssSourceDTO.Item) {
        self.init(title: dto.title, link: dto.link, content: dto.content, pubDate: dto.pubDate, author: dto.author)
    }
}

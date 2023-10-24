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
    
    init() {
        logger.info("home directory: \(NSHomeDirectory())")
    }
    
    func addFeed(url: URL) async throws {
        let dto = try await fetchWebFeed(url: url)
        try await databaseActor.addFeed(url: url, dto: dto)
    }
    
    private func fetchWebFeed(url: URL) async throws -> RssSourceDTO {
        let (data, _) = try await URLSession.api.data(from: url)
        let source = try RssSourceDTO.parse(data: data)
        return source
    }
    
    @MainActor
    func refresh(feeds: [Feed], force: Bool = false) async {
        for feed in feeds {
            do {
                try await updateFeed(feed)
                logger.info("update feed \(feed.title) success")
            } catch {
                logger.error("update feed \(feed.title) failed: \(error.localizedDescription)")
            }
        }
        
        self.lastUpdateTime = .now
    }
    
    private func updateFeed(_ feed: Feed) async throws {
        let dto = try await fetchWebFeed(url: feed.url)
        try await databaseActor.updateFeed(feed.persistentModelID, items: dto.items)
    }
}

extension Feed {
    static func getFeed(by name: String, in context: ModelContext) throws -> Feed? {
        let predicate = #Predicate<Feed> { $0.title == name }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
    }
    
    func lastUpdateTime() -> Date? {
        guard let context = self.modelContext else { return nil }
        let name = self.title
        let predicate = #Predicate<Article> { $0.feed?.title == name }
        return try? context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.pubDate, order: .reverse)])).first?.pubDate
    }
    
    func unreadCount() -> Int {
        guard let context = self.modelContext else { return 0 }
        let name = self.title
        let predicate = #Predicate<Article> { $0.feed?.title == name && $0.viewed == false }
        return try! context.fetch(FetchDescriptor(predicate: predicate)).count
    }
}

extension Article {
    convenience init(from dto: RssSourceDTO.Item) {
        
        self.init(title: dto.title, link: dto.link, content: dto.content, pubDate: dto.pubDate, author: dto.author)
    }
    
    static func article(from dto: RssSourceDTO.Item, in context: ModelContext) -> Article {
        let title = dto.title
        let link = dto.link
        let predicate = #Predicate<Article>() { $0.title == title && $0.link == link }
        
        let article = try? context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Article.pubDate, order: .reverse)])).first
        if let article {
            return article
        }
        
        return Article(from: dto)
    }
}

extension URLSession {
    static var api: URLSession = {
        // Set timeout
        var config = URLSession.shared.configuration
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()
}

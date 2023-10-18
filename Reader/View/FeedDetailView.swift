//
//  RssSourceDetail.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftUI
import SwiftData
import Kingfisher

struct FeedDetailView: View {
    let feed: Feed
    
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Article]
    
    @State private var selectedArticle: Article?
    @State private var enableFilter = false
        
    init(feed: Feed) {
        self.feed = feed
        
        let name = feed.title
        let filter = #Predicate<Article> { $0.feed?.title == name }
        _items = Query(filter: filter, sort: \.pubDate, order: .reverse)
    }
    
    private var articles: [Article] {
        if enableFilter {
            return items.filter { !$0.viewed }
        } else {
            return items
        }
    }
    
    var body: some View {
        List {
            ForEach(articles, id: \.id) { article in
                VStack(alignment: .leading) {
                    Text(article.title).font(.headline).lineLimit(3)
                    HStack {
                        Spacer()
                        Text(DateFormatterFactory.dateString(article.pubDate)).font(.subheadline)
                    }
                }
                .onTapGesture {
                    selectedArticle = article
                    markRead(for: article)
                }
                .foregroundColor(article.viewed ? .secondary : .primary)
            }
        }
        .overlay {
            if articles.isEmpty {
                ContentUnavailableView("No articles", systemImage: "square.on.square")
            }
        }
        .navigationTitle(Text(feed.title))
        .fullScreenCover(item: $selectedArticle) { article in
            WebView(url: article.link).ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $enableFilter) {
                    Image(systemName: enableFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        
                }
                .toggleStyle(.button)
                .foregroundStyle(Color.accentColor)
                .buttonStyle(.plain)
            }
            ToolbarTitleMenu {
                FeedInfoView(feed: feed)
            }
        }
    }
    
    private func markRead(for article: Article) {
        article.viewed = true
    }
}

struct FeedInfoView: View {
    let feed: Feed
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            Text("Total: \(feed.articles.count)")
            Link(destination: feed.homepage) {
                HStack {
                    Text("Open homepage")
                    Spacer()
                    Image(systemName: "safari")
                }
            }
            Button {
                UIPasteboard.general.url = feed.url
            } label: {
                Label("Copy site link", systemImage: "doc.on.doc")
            }
            
            Button {
                for article in feed.articles {
                    article.viewed = true
                }
            } label: {
                Label("Mark all read", systemImage: "app.badge.checkmark")
            }

        }
    }
}

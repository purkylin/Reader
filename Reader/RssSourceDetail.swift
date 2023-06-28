//
//  RssSourceDetail.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftUI
import SwiftData

struct RssSourceDetail: View {
    let source: RssSource
    
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RssFeed]
    
    @State private var selectedFeed: RssFeed?
    @State private var enableFilter = false
    
    init(source: RssSource) {
        self.source = source
        
        let name = source.title
        let filter = #Predicate<RssFeed> { $0.source?.title == name }
        _items = Query(filter: filter, sort: \.pubDate, order: .reverse)
    }
    
    private var feeds: [RssFeed] {
        if enableFilter {
            return items.filter { !$0.viewed }
        } else {
            return items
        }
    }
    
    var body: some View {
        List {
            ForEach(feeds, id: \.title) { feed in
                VStack(alignment: .leading) {
                    Text(feed.title).lineLimit(3)
                    HStack {
                        Spacer()
                        Text(feed.pubDate, style: .relative).font(.subheadline)
                    }
                }
                .onTapGesture {
                    selectedFeed = feed
                    markRead(for: feed)
                }
                .foregroundColor(feed.viewed ? .secondary : .primary)
            }
        }
        .navigationTitle(Text(source.title))
        .fullScreenCover(item: $selectedFeed) { feed in
            WebView(url: feed.link).ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $enableFilter) {
                    Image(systemName: enableFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
            
            ToolbarTitleMenu {
                Link(destination: source.link) {
                    Label("Homepage", systemImage: "arrow.turn.down.left")
                }
            }
        }
    }
    
    private func markRead(for feed: RssFeed) {
        feed.viewed = true
    }
}

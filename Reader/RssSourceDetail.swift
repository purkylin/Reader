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

struct RssSourceDetail: View {
    let source: RssSource
    
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RssFeed]
    
    @State private var selectedFeed: RssFeed?
    @State private var enableFilter = false
    
    @State private var showEditPage = false
    
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
                        Text(DateFormatterFactory.dateString(feed.pubDate)).font(.subheadline)
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
                .toggleStyle(.button)
                .foregroundStyle(Color.accentColor)
                .buttonStyle(.plain)
            }
            
            // ToolbarItem(placement: .principal) {
            //     Button("aa") {
            //         showEditPage = true
            //     }
            // }
            
            // ToolbarTitleMenu {
            //     Button("", action: <#T##() -> Void#>)
            //     SourceEditView(source: source)
            // }
        }
        .sheet(isPresented: $showEditPage, content: {
            SourceEditView(source: source)
        })
    }
    
    private func markRead(for feed: RssFeed) {
        feed.viewed = true
    }
}

struct SourceEditView: View {
    let source: RssSource
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("s")
    }
    // var body2: some View {
    //     NavigationStack {
    //         Form {
    //             if let url = source.icon {
    //                 HStack {
    //                     Spacer()
    //                     KFImage(url)
    //                     Spacer()
    //                 }
    //                 .listRowBackground(EmptyView())
    //             }
    //             Section("Homepage") {
    //                 Link(destination: source.link, label: {
    //                     HStack {
    //                         Text(source.link.absoluteString)
    //                         Spacer()
    //                         Image(systemName: "safari")
    //                     }
    //                 })
    //                 .buttonStyle(.default)
    //             }
    //             
    //             Section("Feed url") {
    //                 Text(source.url.absoluteString)
    //             }
    //         }
    //         .navigationTitle(source.title)
    //         .navigationBarTitleDisplayMode(.inline)
    //         .toolbar {
    //             ToolbarItem(placement: .cancellationAction) {
    //                 Button("Done") {
    //                     dismiss()
    //                 }
    //             }
    //         }
    //     }
    // }
}

//
//  ContentView.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State var selection: Feed?
        
    var body: some View {
        NavigationSplitView {
            FeedListView(selection: $selection)
        } detail: {
            if let feed = selection {
                FeedDetailView(feed: feed)
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Feed.self, inMemory: true)
}



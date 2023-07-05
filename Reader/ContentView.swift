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
    var body: some View {
        NavigationStack {
            FeedListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

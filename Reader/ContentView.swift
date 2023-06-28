//
//  ContentView.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            RssSourceList()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

//
//  ReaderApp.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import SwiftUI
import SwiftData

let globalContainer = try! ModelContainer(for: Feed.self)

@main
struct ReaderApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(globalContainer)
    }
}




//
//  ReaderApp.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import SwiftUI
import SwiftData

let globalContainer = try! ModelContainer(for: Feed.self)
let databaseActor = BackgroundActor(container: globalContainer)

@main
struct ReaderApp: App {
    @AppStorage("EnabledAutoClean") var enabledAutoClean = false

    // TODO: Background task
    private let store = Store()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task {
                    if enabledAutoClean {
                        await store.clean()
                    }
                }
            
        }
        .modelContainer(globalContainer)
    }
}




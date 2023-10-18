//
//  ReaderApp.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import SwiftUI
import SwiftData
import TipKit

let globalContainer = try! ModelContainer(for: Feed.self)
let databaseActor = BackgroundActor(modelContainer: globalContainer)

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
#if DEBUG
                    try? Tips.resetDatastore()
#endif
                    
                    try? Tips.configure([
                        .datastoreLocation(.applicationDefault),
                        .displayFrequency(.immediate)
                    ])
                    
                    if enabledAutoClean {
                        await databaseActor.clean()
                    }
                }
        }
        .modelContainer(globalContainer)
    }
}

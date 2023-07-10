//
//  BackgroundActor.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/10.
//

import Foundation
import SwiftData

actor BackgroundActor: ModelActor {
    nonisolated public let executor: any ModelExecutor
    
    init(container: ModelContainer) {
        let context = ModelContext(container)
        executor = DefaultModelExecutor(context: context)
    }
    
    func run(task: (ModelContext) -> Void) {
        task(context)
    }
}

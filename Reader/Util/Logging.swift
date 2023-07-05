//
//  Logging.swift
//  Reader
//
//  Created by Purkylin King on 2023/7/3.
//

import Foundation
import OSLog

protocol Logging {
    var logger: Logger { get }
}

extension Logging {
    var logger: Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: type(of: self)))
    }
}

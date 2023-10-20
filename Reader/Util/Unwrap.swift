//
//  Unwrap.swift
//  Reader
//
//  Created by Purkylin King on 2023/10/20.
//

import Foundation

extension Optional {
    func unwrap() -> Wrapped {
        switch self {
        case .some(let v):
            return v
        default:
            fatalError("Value is None")
        }
    }
    
    func unwrap(default: Wrapped) -> Wrapped {
        switch self {
        case .some(let v):
            return v
        default:
            return `default`
        }
    }
}

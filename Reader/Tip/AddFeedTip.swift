//
//  AddFeedTip.swift
//  Reader
//
//  Created by Purkylin King on 2023/10/18.
//

import SwiftUI
import TipKit

struct AddFeedTip: Tip {
    @Parameter
    static var donated: Bool = false
    
    var title: Text {
        Text("Add new feed")
    }
    
    var message: Text? {
        Text("More articles in your feed")
    }
    
    var image: Image? {
        Image(systemName: "star")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$donated) {
                $0 != true
            }
        ]
    }
}

//
//  Item.swift
//  FreeTube
//
//  Created by eric ho on 13/2/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

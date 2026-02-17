//
//  Item.swift
//  MurderBoard
//
//  Created by Mike Stoddard on 2/17/26.
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

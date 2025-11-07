//
//  Item.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
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

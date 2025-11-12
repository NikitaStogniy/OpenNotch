//
//  TodoItem.swift
//  Notch
//
//  Created for OpenNotch
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var dateCreated: Date

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.dateCreated = Date()
    }
}

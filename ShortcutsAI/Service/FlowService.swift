//
//  FlowService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/2.
//

import Foundation
import RealmSwift
import SwiftUI

class Flow: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var prompt: String
    @Persisted var model: String
    @Persisted var temperature: Float
    @Persisted var fixed = true
    @Persisted var prefer: String = FlowPrefer.clipboard.rawValue
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
}

enum FlowPrefer: String, CaseIterable {
    case clipboard
    case screenshot
}

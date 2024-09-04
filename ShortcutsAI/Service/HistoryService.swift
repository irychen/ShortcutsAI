//
//  HistoryRecordService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/4.
//

import Foundation
import RealmSwift
import SwiftUI

class History: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var input: String
    @Persisted var result: String
    @Persisted var createdAt: Date

    convenience  init(dto: HistoryDto) {
        self.init()
        self.name = dto.name
        self.input = dto.input
        self.result = dto.result
        self.createdAt = Date()
    }

}

struct HistoryDto: Codable {
    var name: String
    var input: String
    var result: String
}

class HistoryService{
    static let shared = HistoryService()
    private let realm: Realm
    
    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    // Create
    func create(_ dto: HistoryDto) throws {
        deleteOldHistory()
        let h = History(dto: dto)
        do {
            try realm.write {
                realm.add(h)
            }
        } catch {
            throw error
        }
    }
    
    // delete 30 days ago history
    func deleteOldHistory() {
        let date = Date().addingTimeInterval(-30*24*60*60)
        let oldHistory = realm.objects(History.self).filter("createdAt < %@", date)
        try! realm.write {
            realm.delete(oldHistory)
        }
    }
    
    // delete by id
    func delete(_ id: ObjectId) throws {
        guard let h = realm.object(ofType: History.self, forPrimaryKey: id) else {
            return
        }
        do {
            try realm.write {
                realm.delete(h)
            }
        } catch {
            throw error
        }
    }
}

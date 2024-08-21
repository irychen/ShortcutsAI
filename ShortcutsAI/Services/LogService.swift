//
//  LogService.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import CoreData
import SwiftUI


class LogService {
    static let shared = LogService()
    private let ctx = PersistenceController.shared.container.viewContext
    private init() {}
    
    func log(level : LogLevel, message : String, detail: String){
        deleteLogs()
        let log = Log(context: ctx)
        log.timestamp = Date()
        log.level = level.rawValue
        log.message = message
        log.detail = detail
        do {
            try ctx.save()
        } catch {
            print("Failed to save log")
        }
    }
    
    func log(level : LogLevel, message : String){
        deleteLogs()
        let log = Log(context: ctx)
        log.timestamp = Date()
        log.level = level.rawValue
        log.message = message
        do {
            try ctx.save()
        } catch {
            print("Failed to save log")
        }
    }
    
    func getLogs() -> [Log] {
        deleteLogs()
        let request: NSFetchRequest<Log> = Log.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            return try ctx.fetch(request)
        } catch {
            return []
        }
    }
    
    // delete logs before a month
    func deleteLogs() {
        let request: NSFetchRequest<Log> = Log.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp < %@", Date().addingTimeInterval(-30*24*60*60) as NSDate)
        do {
            let logs = try ctx.fetch(request)
            for log in logs {
                ctx.delete(log)
            }
            try ctx.save()
        } catch {
            print("Failed to delete logs")
        }
    }
}


enum LogLevel: String, CaseIterable {
    case info = "info"
    case fatal = "fatal"
    case warn = "warn"
    case error = "error"

    var displayName: String {
        switch self {
        case .info:
            return "INFO"
        case .fatal:
            return "FATAL"
        case .warn:
            return "WARN"
        case .error:
            return "ERROR"
        }
    }

    var color: Color {
        switch self {
        case .info:
            return .green
        case .fatal:
            return .red
        case .warn:
            return .orange
        case .error:
            return .red
        }
    }
}

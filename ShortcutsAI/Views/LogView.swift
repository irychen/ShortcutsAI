//
//  LogView.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/11.
//

import SwiftUI
import CoreData


struct LogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Log.timestamp, ascending: false)],
        animation: .default)
    private var logs: FetchedResults<Log>
    
    var body: some View {
        VStack {
            Text("Logs")
                .font(.system(size: 16))
                .padding()
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(logs, id: \.id) { log in
                        LogRow(log: log)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct LogRow: View {
    var log: Log
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(log.detail ?? "No Detail")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(log.message ?? "No Message")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(log.timestamp ?? Date(), formatter: itemFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let level = LogLevel(rawValue: log.level ?? "") {
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(level.color)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            } else {
                Text("UNKNOWN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

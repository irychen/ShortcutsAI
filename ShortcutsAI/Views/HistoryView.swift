//
//  HistoryView.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/8.
//

import Foundation
import RealmSwift
import SwiftUI

struct HistoryView: View {
    @ObservedResults(History.self, sortDescriptor: SortDescriptor(keyPath: "createdAt", ascending: false)) var history

    var body: some View {
        VStack {
            Text("History")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
                .background(Color.white.opacity(0.001))
                .font(.system(size: 18, weight: .bold))
                .draggable()
            if history.isEmpty {
                VStack {
                    Text("No history yet.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(history) { record in
                        HistoryRow(record: record)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryRow: View {
    let record: History
    @Environment(\.colorScheme) private var colorScheme
    @State private var isCopied = false

    func copyToClipboard(_ text: String) {
        try! ClipboardService.shared.save(text)
    }

    func copyResult() {
        copyToClipboard(record.result)
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCopied = false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                HStack {
                    Button(action: {
                        try! HistoryService.shared.delete(record._id)
                    }) {
                        Image(systemName: "trash")
                    }
                    Button(action: copyResult) {
                        Image(systemName: isCopied ? "list.bullet.clipboard" : "doc.on.doc")
                    }.padding(.leading, 8)
                }.buttonStyle(BorderlessButtonStyle())
            }
            if !record.input.isEmpty {
                ThemedMarkdownText(record.input,
                                   fontSize: 12,
                                   codeFont: .monospaced(.body)(),
                                   wrapCode: true)

                Divider()
            }
      
            ThemedMarkdownText(record.result,
                               fontSize: 12,
                               codeFont: .monospaced(.body)(),
                               wrapCode: true)

            Text("Created at: \(formattedDate(record.createdAt))")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(
            colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.75)
        ))
//        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

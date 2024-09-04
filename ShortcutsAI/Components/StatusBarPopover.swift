//
//  StatusBarPopover.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/9/9.
//

import Foundation
import SwiftUI

struct StatusBarPopover: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(\.outputText) private var outputText
    @AppStorage(\.inputText) private var inputText
    @AppStorage(\.globalRunLoading) private var globalRunLoading
    func copyToClipboard(_ text: String) {
        try! ClipboardService.shared.save(text)
    }

    var close: (() -> Void)?
    var body: some View {
        VStack {
            HStack {
                Text("Shortcuts AI")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                    .background(Color.white.opacity(0.001))
                    .font(.system(size: 15, weight: .bold))
            }.padding(.top, 10)
            AutoresizingTextEditor(
                text: $inputText,
                font: .systemFont(ofSize: 12),
                isEditable: true,
                maxHeight: 60,
                lineSpacing: 4,
                placeholder: "your input text will be displayed here."
            ) {}.padding(8).background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.12))
                }
            ).padding(.horizontal, 20)
            HStack {
                Space(direction: .horizontal) {
                    Button(action: {
                        copyToClipboard(inputText)
                    }) {
                        Text("Copy Input")
                    }.buttonStyle(NormalButtonStyle())
                    Button(action: {
                        copyToClipboard(outputText)
                    }) {
                        Text("Copy Output")
                    }.buttonStyle(NormalButtonStyle())
                    Button(action: {
                        close?()
                    }) {
                        Text("Close")
                    }.buttonStyle(NormalButtonStyle())
                    
                    HStack {
                        if globalRunLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.5, anchor: .center)
                                .frame(width: 5, height: 5)
                                .padding(0)
                                .padding(.leading, 10)
                        }
                    }.frame(width: 20)
                }
            }.padding(.vertical, 10)
            ScrollView(.vertical) {
                if outputText.isEmpty {
                    Text("Output will be displayed here.").padding(12).frame(maxWidth: .infinity, alignment: .topLeading)
                }
                ThemedMarkdownText(outputText,
                                   fontSize: 14,
                                   codeFont: .monospaced(.body)(),
                                   wrapCode: true).padding(12).frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                }
            ).padding(.horizontal, 20).padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(hex: "#333") : Color.white.opacity(0.7))
    }
}

//
//  CodeBlock.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/8.
//

import Foundation
import MarkdownUI
import SwiftUI

struct CodeBlock: View {
    let configuration: CodeBlockConfiguration
    let codeFont: Font
    let wrapCode: Bool
    let colorScheme: ColorScheme

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(configuration.language ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "#727072") : Color(hex: "#8E8E8E")).padding(.bottom, 8)
                Spacer()
                Button(action: copyCode) {
                    Image(systemName: isCopied ? "list.bullet.clipboard" : "doc.on.doc")
                }
                .buttonStyle(.plain)
            }

            if wrapCode {
                codeView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    codeView
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "#2D2A2E") : Color(hex: "#F5F5F5"))
        .cornerRadius(8)
    }

    private var codeView: some View {
        Text(AttributedString(highlightedCode))
            .font(codeFont)
            .textSelection(.enabled)
    }

    private var highlightedCode: NSAttributedString {
        let highlighter = SyntaxHighlighter(colorScheme: colorScheme)
        return highlighter.highlight(configuration.content, language: configuration.language ?? "")
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(configuration.content, forType: .string)

        withAnimation {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

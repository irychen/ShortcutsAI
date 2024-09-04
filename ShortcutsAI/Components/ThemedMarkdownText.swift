//
//  ThemedMarkdownText.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/8.
//

import Foundation
import MarkdownUI
import SwiftUI

struct ThemedMarkdownText: View {
    let content: MarkdownContent
    let fontSize: CGFloat
    let codeFont: Font
    let wrapCode: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(_ text: String, fontSize: CGFloat, codeFont: Font, wrapCode: Bool) {
        content = MarkdownContent(text)
        self.fontSize = fontSize
        self.codeFont = codeFont
        self.wrapCode = wrapCode
    }

    var body: some View {
        Markdown(content)
            .textSelection(.enabled)
            .markdownTheme(customTheme)
    }

    private var customTheme: Theme {
        Theme()
            .paragraph { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.2))
            }
            .text {
                ForegroundColor(.primary)
                BackgroundColor(.clear)
                FontSize(fontSize)
            }
            .codeBlock { configuration in
                CodeBlock(configuration: configuration,
                          codeFont: codeFont,
                          wrapCode: wrapCode,
                          colorScheme: colorScheme)
            }
    }
}

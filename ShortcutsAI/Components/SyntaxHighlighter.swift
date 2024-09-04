//
//  SyntaxHighlighter.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/6.
//

import Foundation
import SwiftUI

class SyntaxHighlighter {
    let colorScheme: ColorScheme

    // Monokai Pro (Filter Spectrum) colors for dark mode
    let darkColors = [
        "text": NSColor(hex: "#FFF1F3"),
        "keyword": NSColor(hex: "#FF6188"),
        "string": NSColor(hex: "#FFD866"),
        "number": NSColor(hex: "#AB9DF2"),
        "comment": NSColor(hex: "#727072"),
        "type": NSColor(hex: "#78DCE8"),
        "function": NSColor(hex: "#A9DC76"),
    ]

    // Custom light mode colors
    let lightColors = [
        "text": NSColor(hex: "#383A42"),
        "keyword": NSColor(hex: "#A626A4"),
        "string": NSColor(hex: "#50A14F"),
        "number": NSColor(hex: "#986801"),
        "comment": NSColor(hex: "#A0A1A7"),
        "type": NSColor(hex: "#0184BC"),
        "function": NSColor(hex: "#4078F2"),
    ]

    init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    func highlight(_ code: String, language _: String) -> NSAttributedString {
        let colors = colorScheme == .dark ? darkColors : lightColors
        let attributedString = NSMutableAttributedString(string: code)
        attributedString.addAttribute(.foregroundColor, value: colors["text"]!, range: NSRange(location: 0, length: code.utf16.count))

        // Define regex patterns for different syntax elements
        let patterns: [(String, String)] = [
            ("\\b(func|var|let|if|else|for|while|struct|class|enum|switch|case|return|import|guard|defer|do|repeat|try|catch|throw|where|in|as|is|new|true|false|nil)\\b", "keyword"),
            ("\".*?\"", "string"),
            ("\\b[0-9]+\\b", "number"),
            ("//.*", "comment"),
            ("/\\*[\\s\\S]*?\\*/", "comment"),
            ("\\b[A-Z][a-zA-Z]*\\b", "type"),
            ("\\b[a-z]+(?=\\()", "function"),
        ]

        for (pattern, colorKey) in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: code.utf16.count)
                let matches = regex.matches(in: code, options: [], range: range)

                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: colors[colorKey]!, range: match.range)
                }
            } catch {
                print("Error creating regex: \(error)")
            }
        }

        return attributedString
    }
}

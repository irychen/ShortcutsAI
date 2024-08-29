//
//  Color.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/30.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let r, g, b, a: Double
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x0000_00FF) / 255

                    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                    return
                }

            } else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000FF) / 255
                    a = 1

                    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                    return
                }
            } else if hexColor.count == 3 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xF00) >> 8) / 15
                    g = CGFloat((hexNumber & 0x0F0) >> 4) / 15
                    b = CGFloat(hexNumber & 0x00F) / 15
                    a = 1

                    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                    return
                }
            }
        }

        self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
        return
    }

    func toNSColor() -> NSColor {
        let components = NSColor(self).cgColor.components ?? [0, 0, 0, 1]
        return NSColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }

    static func dynamicColor(lightColor: Color, darkColor: Color) -> Color {
        Color(NSColor(name: nil, dynamicProvider: { appearance in
            appearance.name == .darkAqua ? darkColor.toNSColor() : lightColor.toNSColor()
        }))
    }
}

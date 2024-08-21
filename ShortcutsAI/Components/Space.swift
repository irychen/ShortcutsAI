//
//  Space.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import SwiftUI
import Cocoa
import AppKit


struct Space<Content: View>: View {
    let direction: Axis.Set
    let spacing: CGFloat
    let alignment: Alignment
    let views: [Content]

    init(direction: Axis.Set = .vertical, spacing: CGFloat = 8, alignment: Alignment = .center, @ViewBuilder content: () -> Content) {
        self.direction = direction
        self.spacing = spacing
        self.alignment = alignment
        self.views = [content()]
    }

    var body: some View {
        Group {
            if direction == .vertical {
                VStack(alignment: alignment.horizontal, spacing: spacing) {
                    ForEach(0..<views.count, id: \.self) { index in
                        views[index]
                    }
                }
            } else {
                HStack(alignment: alignment.vertical, spacing: spacing) {
                    ForEach(0..<views.count, id: \.self) { index in
                        views[index]
                    }
                }
            }
        }
    }
}


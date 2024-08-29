//
//  Space.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/30.
//

import AppKit
import Cocoa
import Foundation
import SwiftUI

struct Space<Content: View>: View {
    let direction: Axis.Set
    let spacing: CGFloat
    let alignment: Alignment
    let views: [Content]

    init(direction: Axis.Set = .vertical, spacing: CGFloat = 8, alignment: Alignment = .center, @ViewBuilder content: () -> Content) {
        self.direction = direction
        self.spacing = spacing
        self.alignment = alignment
        views = [content()]
    }

    var body: some View {
        Group {
            if direction == .vertical {
                VStack(alignment: alignment.horizontal, spacing: spacing) {
                    ForEach(0 ..< views.count, id: \.self) { index in
                        views[index]
                    }
                }
            } else {
                HStack(alignment: alignment.vertical, spacing: spacing) {
                    ForEach(0 ..< views.count, id: \.self) { index in
                        views[index]
                    }
                }
            }
        }
    }
}

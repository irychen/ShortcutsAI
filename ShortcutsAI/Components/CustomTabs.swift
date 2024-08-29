//
//  CustomTabs.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/30.
//

import Foundation
import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let key: String
    let view: AnyView
}

struct CustomTabView: View {
    let tabs: [TabItem]
    @Binding var currentKey: String
    let onChange: (String) -> Void = { _ in }

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabButton(
                    label: tab.label,
                    icon: tab.icon,
                    isSelected: currentKey == tab.key,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if currentKey != tab.key {
                            currentKey = tab.key
                            onChange(tab.key)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.dynamicColor(lightColor: .white, darkColor: Color(hex: "#333")).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

struct TabButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.05))
                            .matchedGeometryEffect(id: "background", in: namespace)
                    }
                }
            )
            .foregroundColor(isSelected ? Color.dynamicColor(lightColor: Color.blue, darkColor: Color(hex: "#4BA1FF")) : Color.dynamicColor(lightColor: Color(hex: "#666"), darkColor: Color(hex: "#ccc")))
        }
        .buttonStyle(TabButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

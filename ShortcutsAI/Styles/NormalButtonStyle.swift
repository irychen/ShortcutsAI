import Foundation
import SwiftUI

struct NormalButtonStyle: ButtonStyle {
    var isPrimary: Bool = false
    var isDanger: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor(for: configuration))
            .foregroundColor(foregroundColor(for: configuration))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(strokeColor(for: configuration), lineWidth: 0.5)
            )
    }

    private func backgroundColor(for configuration: Configuration) -> Color {
        if isDanger {
            return configuration.isPressed ? Color.red.opacity(0.3) : Color.red.opacity(0.1)
        }
        if isPrimary {
            return configuration.isPressed ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)
        }
        return configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear
    }

    private func foregroundColor(for _: Configuration) -> Color {
        if isDanger {
            return .red
        }
        if isPrimary {
            return .blue
        }
        return .primary
    }

    private func strokeColor(for _: Configuration) -> Color {
        if isDanger {
            return .red.opacity(0.5)
        }
        if isPrimary {
            return .blue.opacity(0.5)
        }
        return .gray.opacity(0.5)
    }
}

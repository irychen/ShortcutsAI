import Foundation
import SwiftUI

struct NormalButtonStyle: ButtonStyle {
    var isPrimary: Bool = false
    var isDanger: Bool = false
    var isWarning: Bool = false
    var isSuccess: Bool = false
    var isDisabled: Bool = false

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
        if isDisabled {
            return Color.gray.opacity(0.2)
        }
        if isDanger {
            return configuration.isPressed ? Color.red.opacity(0.3) : Color.red.opacity(0.1)
        }
        if isPrimary {
            return configuration.isPressed ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)
        }
        if isWarning {
            return configuration.isPressed ? Color.orange.opacity(0.3) : Color.orange.opacity(0.1)
        }
        if isSuccess {
            return configuration.isPressed ? Color.green.opacity(0.3) : Color.green.opacity(0.1)
        }
        return configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear
    }

    private func foregroundColor(for _: Configuration) -> Color {
        if isDisabled {
            return .gray
        }
        if isDanger {
            return .red
        }
        if isPrimary {
            return .blue
        }
        if isWarning {
            return .orange
        }
        if isSuccess {
            return .green
        }
        return .primary
    }

    private func strokeColor(for _: Configuration) -> Color {
        if isDisabled {
            return .gray.opacity(0.5)
        }
        if isDanger {
            return .red.opacity(0.5)
        }
        if isPrimary {
            return .blue.opacity(0.5)
        }
        if isWarning {
            return .orange.opacity(0.5)
        }
        if isSuccess {
            return .green.opacity(0.5)
        }

        return .gray.opacity(0.5)
    }
}

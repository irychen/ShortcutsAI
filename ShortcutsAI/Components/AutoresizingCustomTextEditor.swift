import Foundation
import SwiftUI

public struct AutoresizingCustomTextEditor: View {
    @Binding public var text: String
    public let font: NSFont
    public let isEditable: Bool
    public let maxHeight: Double
    public let lineSpacing: CGFloat
    public let placeholder: String?
    public let onSubmit: (() -> Void)?
    public var completions: ((_ text: String, _ words: [String], _ range: NSRange) -> [String])?

    public init(
        text: Binding<String>,
        font: NSFont,
        isEditable: Bool,
        maxHeight: Double,
        lineSpacing: CGFloat,
        placeholder: String? = nil,
        onSubmit: @escaping () -> Void,
        completions: @escaping (_ text: String, _ words: [String], _ range: NSRange) -> [String] = { _, _, _ in [] }

    ) {
        _text = text
        self.font = font
        self.isEditable = isEditable
        self.maxHeight = maxHeight
        self.lineSpacing = lineSpacing
        self.onSubmit = onSubmit
        self.completions = completions
        self.placeholder = placeholder
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty, let placeholder {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.init(font))
                    .lineSpacing(lineSpacing)
                    .padding(.top, 1)
                    .padding(.bottom, 2)
                    .padding(.horizontal, 4)
            }

            CustomTextEditor(
                text: $text,
                font: font,
                isEditable: isEditable,
                lineSpacing: lineSpacing,
                onSubmit: onSubmit ?? {},
                completions: completions ?? { _, _, _ in [] }
            )
            .frame(maxWidth: .infinity, maxHeight: maxHeight)
            .padding(.top, 1)
            .padding(.bottom, -1)
        }
    }
}

public struct CustomTextEditor: NSViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @Binding public var text: String
    public let font: NSFont
    public let isEditable: Bool
    public let lineSpacing: CGFloat
    public let onSubmit: () -> Void
    public var completions: (_ text: String, _ words: [String], _ range: NSRange) -> [String]

    public init(
        text: Binding<String>,
        font: NSFont,
        isEditable: Bool = true,
        lineSpacing: CGFloat,
        onSubmit: @escaping () -> Void,
        completions: @escaping (_ text: String, _ words: [String], _ range: NSRange) -> [String] = { _, _, _ in [] }
    ) {
        _text = text
        self.font = font
        self.isEditable = isEditable
        self.lineSpacing = lineSpacing
        self.onSubmit = onSubmit
        self.completions = completions
    }

    public func makeNSView(context: Context) -> NSScrollView {
        context.coordinator.completions = completions
        let textView = (context.coordinator.theTextView.documentView as! NSTextView)
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = font
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        // Set line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes[.paragraphStyle] = paragraphStyle

        return context.coordinator.theTextView
    }

    public func updateNSView(_: NSScrollView, context: Context) {
        context.coordinator.completions = completions
        let textView = (context.coordinator.theTextView.documentView as! NSTextView)
        textView.isEditable = isEditable

        // Update line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes[.paragraphStyle] = paragraphStyle

        guard textView.string != text else { return }
        textView.string = text
        textView.undoManager?.removeAllActions()
    }
}

public extension CustomTextEditor {
    class Coordinator: NSObject, NSTextViewDelegate {
        var view: CustomTextEditor
        var theTextView = NSTextView.scrollableTextView()
        var affectedCharRange: NSRange?
        var completions: (String, [String], _ range: NSRange) -> [String] = { _, _, _ in [] }

        init(_ view: CustomTextEditor) {
            self.view = view
        }

        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            view.text = textView.string
            textView.complete(nil)
        }

        public func textView(
            _: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSTextView.insertNewline(_:)) {
                if let event = NSApplication.shared.currentEvent,
                   !event.modifierFlags.contains(.shift),
                   event.keyCode == 36 // enter
                {
                    view.onSubmit()
                    return true
                }
            }

            return false
        }

        public func textView(
            _: NSTextView,
            shouldChangeTextIn _: NSRange,
            replacementString _: String?
        ) -> Bool {
            true
        }

        public func textView(
            _ textView: NSTextView,
            completions words: [String],
            forPartialWordRange charRange: NSRange,
            indexOfSelectedItem index: UnsafeMutablePointer<Int>?
        ) -> [String] {
            index?.pointee = -1
            return completions(textView.textStorage?.string ?? "", words, charRange)
        }
    }
}

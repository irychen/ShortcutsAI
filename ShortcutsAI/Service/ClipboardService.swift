import AppKit
import Foundation

class ClipboardService {
    static let shared = ClipboardService()
    private let clipboard = NSPasteboard.general
    private init() {}

    /// Saves an item to the clipboard.
    /// - Parameter item: The item to save. Can be NSImage or String.
    /// - Throws: An error if the item type is not supported.
    func save(_ item: some Any) throws {
        clipboard.clearContents()
        switch item {
        case let image as NSImage:
            guard clipboard.writeObjects([image]) else {
                throw ClipboardError.failedToSave
            }
        case let text as String:
            guard clipboard.setString(text, forType: .string) else {
                throw ClipboardError.failedToSave
            }
        default:
            throw ClipboardError.unsupportedType
        }
    }

    /// Retrieve the content from the clipboard
    /// - Parameter type: The type of item to retrieve (NSImage.self or String.self).
    /// - Returns: The retrieved item, or nil if not found.
    func retrieve<T>(_ type: T.Type) -> T? {
        switch type {
        case is NSImage.Type:
            guard let objects = clipboard.readObjects(forClasses: [NSImage.self], options: nil),
                  let image = objects.first as? NSImage
            else {
                return nil
            }
            return image as? T
        case is String.Type:
            return clipboard.string(forType: .string) as? T
        default:
            return nil
        }
    }

    func clear() {
        clipboard.clearContents()
    }
}

enum ClipboardError: Error {
    case unsupportedType
    case failedToSave
}

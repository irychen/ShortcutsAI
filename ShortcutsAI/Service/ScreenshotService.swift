
import Foundation
import SwiftUI

class ScreenshotService {
    static let shared = ScreenshotService()
    private init() {}

    static func take() -> NSImage? {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        task.launch()
        task.waitUntilExit()
        return ClipboardService.shared.retrieve(NSImage.self)
    }
}

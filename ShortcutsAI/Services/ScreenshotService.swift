//
//  ScreenshotService.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//
import Foundation
import SwiftUI


class ScreenshotService {
    static let shared = ScreenshotService()
    private init() {}
    
    
    static func take() -> NSImage? {
        // 调用系统截图功能
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        task.launch()
        task.waitUntilExit()
        return ClipboardService.shared.retrieve(NSImage.self)
    }
}

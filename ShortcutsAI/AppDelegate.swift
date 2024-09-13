import Foundation
import SwiftUI



class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusBar: StatusBar?
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        statusBar = StatusBar(showPopover: showPopover, hidePopover: hidePopover)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 460, height: 400)
        popover.behavior = .transient
    
    }
    
    
    func showPopover() {
        if popover.contentViewController == nil {
            popover.contentViewController = NSHostingController(rootView: StatusBarPopover(
                close: hidePopover
            ))
        }
        
        if let button = statusBar?.statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func hidePopover() {
        popover.performClose(nil)
    }
    
    deinit {}
}


func locateHostBundleURL(url: URL) -> URL? {
    var nextURL = url
    while nextURL.path != "/" {
        nextURL = nextURL.deletingLastPathComponent()
        if nextURL.lastPathComponent.hasSuffix(".app") {
            return nextURL
        }
    }
    let devAppURL = url
        .deletingLastPathComponent()
        .appendingPathComponent("ShortcutsAI.app")
    return devAppURL
}

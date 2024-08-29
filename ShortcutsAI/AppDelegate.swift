
import Foundation
import SwiftUI

// class AppDelegate: NSObject, NSApplicationDelegate {
//    var window: NSWindow!
//    var statusBar: StatusBar?
////    var popover: NSPopover!
//
//    private let ctx = PersistenceController.shared.container.viewContext
//    func applicationDidFinishLaunching(_: Notification) {
//        NSApp.activate(ignoringOtherApps: true)
//        statusBar = StatusBar()
//
//        setupCoreDataObserver()
//
////        // 创建弹窗
////        popover = NSPopover()
////        popover.contentSize = NSSize(width: 300, height: 200)
////        popover.behavior = .transient
////
////        // 设置初始弹窗内容
////        popover.contentViewController = NSHostingController(rootView: PopoverContentView(result: "Waiting for OCR..."))
//
//        // 模拟 OCR 功能执行并弹出结果
////        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
////            self.showOCRResult(result: "This is the OCR result.")
////        }
//    }
//
////    @objc func togglePopover() {
////        if let button = statusBar?.statusItem.button {
////            if popover.isShown {
////                popover.performClose(nil)
////            } else {
////                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
////            }
////        }
////    }
//
////    func showOCRResult(result: String) {
////        popover.contentViewController = NSHostingController(rootView: PopoverContentView(result: result))
////        if let button = statusBar?.statusItem.button {
////            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
////        }
////    }
//
//    private func setupCoreDataObserver() {
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(managedObjectContextDidSave),
//            name: NSManagedObjectContext.didSaveObjectsNotification,
//            object: ctx
//        )
//    }
//
//    @objc private func managedObjectContextDidSave(_: Notification) {
//        DispatchQueue.main.async { [weak self] in
//            self?.statusBar?.loadMenu()
//        }
//    }
//
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
// }
//
// struct PopoverContentView: View {
//    let result: String
//
//    var body: some View {
//        VStack {
//            Text("OCR Result:")
//                .font(.headline)
//            Text(result)
//                .padding()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding()
//    }
// }

//
//  AppDelegate.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import SwiftUI
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusBar: StatusBar?
    private let ctx = PersistenceController.shared.container.viewContext
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        statusBar = StatusBar()
        
        setupCoreDataObserver()
    }

    private func setupCoreDataObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: NSManagedObjectContext.didSaveObjectsNotification,
            object: ctx
        )
    }

    @objc private func managedObjectContextDidSave(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.statusBar?.loadMenu()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

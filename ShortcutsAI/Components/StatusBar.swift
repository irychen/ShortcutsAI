//
//  StatusBar.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/9/9.
//

import AppKit
import Foundation
import RealmSwift
import SwiftUI

class StatusBar {
    var showPopover: (() -> Void)?
    var hidePopover: (() -> Void)?
    // camera.metering.center.weighted
    // wand.and.rays
    // square.3.layers.3d.middle.filled
    var notificationToken: NotificationToken?
    private var loadingIcon = "hourglass.bottomhalf.filled"
    private var normalIcon = "wand.and.rays"
    private var menu: NSMenu
    
    var statusBar: NSStatusBar
    var statusItem: NSStatusItem
    
    @AppStorage(\.outputText) private var outputText
    @AppStorage(\.inputText) private var inputText
    @AppStorage(\.autoOpenResultPanel) private var autoOpenResultPanel
    @AppStorage(\.autoSaveToClipboard) private var autoSaveToClipboard

    private let realm: Realm
    
    @AppStorage(\.currentAppTabKey) var currentAppTabKey
    
    @State private var cancel: (() -> Void)?
    @AppStorage(\.globalRunLoading) private var globalRunLoading
    @AppStorage(\.homeSelectedFlowName) private var homeSelectedFlowName
    
    init(showPopover: (() -> Void)? = nil, hidePopover: (() -> Void)? = nil) {
        self.showPopover = showPopover
        self.hidePopover = hidePopover
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        do {
            realm = try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: normalIcon, accessibilityDescription: nil)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleClick)
        }
        let flows = realm.objects(Flow.self).sorted(byKeyPath: "order", ascending: true).filter("fixed = true")
        notificationToken = flows.observe { [weak self] (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let flows), .update(let flows, _, _, _):
                self?.registerMenu(flows: flows)
            case .error(let error):
                print("Realm notification error: \(error)")
            }
        }
    }

    func setNormalIcon() {
        if let button = statusItem.button {
            DispatchQueue.main.sync {
                button.image = NSImage(systemSymbolName: normalIcon, accessibilityDescription: nil)
            }
        }
    }
    
    func setLoadingIcon() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: loadingIcon, accessibilityDescription: nil)
        }
    }
    
    func registerMenu(flows: Results<Flow>) {
        menu.removeAllItems()
        // group title Flows
        
        // -------------------- Flows --------------------
        
        for flow in flows {
            let menuItem = NSMenuItem(title: flow.name, action: #selector(menuItemClicked(_:)), keyEquivalent: "")
            menuItem.representedObject = flow
            menuItem.target = self
            menu.addItem(menuItem)
        }
        
        // -------------------- Functions ----------------
        
        menu.addItem(NSMenuItem.separator())
        let ocrTextItem = NSMenuItem(title: "OCR Text", action: #selector(ocrText), keyEquivalent: "")
        ocrTextItem.target = self
        menu.addItem(ocrTextItem)
        // Take Screenshot
        let ocrScreenshotItem = NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: "")
        ocrScreenshotItem.target = self
        menu.addItem(ocrScreenshotItem)
        
        // -------------------- Other Menu Items --------------------
        
        menu.addItem(NSMenuItem.separator())
        // open main app
        let openMainAppItem = NSMenuItem(title: "Open ShortcutsAI", action: #selector(openHome), keyEquivalent: "")
        openMainAppItem.target = self
        menu.addItem(openMainAppItem)
        // open translator
        let openTranslateItem = NSMenuItem(title: "Translator", action: #selector(openTranslate), keyEquivalent: "")
        openTranslateItem.target = self
        menu.addItem(openTranslateItem)
        
        // open settings
        let openSettingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "")
        openSettingsItem.target = self
        menu.addItem(openSettingsItem)
        
        // -------------------- Quit --------------------
        
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc func ocrText() {
        let ocrSvc = OCRService.shared
        if let image = ScreenshotService.take() {
            do {
                let text = try ocrSvc.recognize(image)
                inputText = text
                outputText = ""
                if autoOpenResultPanel {
                    showPopover?()
                }
                // save History
                DispatchQueue.main.async {
                    try! HistoryService.shared.create(HistoryDto(name: "OCR Text", input: "", result: text))
                }
            } catch {
                print("OCR Error: \(error)")
            }
        }
    }
    
    @objc func takeScreenshot() {
        if let image = ScreenshotService.take() {
            try! ClipboardService.shared.save(image)
        }
    }
    
    @objc func openHome() {
        currentAppTabKey = "home"
        openMainApp()
    }
    
    @objc func openTranslate() {
        currentAppTabKey = "translator"
        openMainApp()
    }
    
    @objc func openSettings() {
        currentAppTabKey = "settings"
        openMainApp()
    }
    
    @objc func openMainApp() {
        let task = Process()
        if let appPath = locateHostBundleURL(url: Bundle.main.bundleURL)?.absoluteString {
            task.launchPath = "/usr/bin/open"
            task.arguments = [appPath]
            task.launch()
            task.waitUntilExit()
        }
    }
    
    @objc func handleClick() {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                print("Right click")
                
                excuteShortcutFlow()
                
            } else {
                print("Left click")
                statusItem.menu = menu
                statusItem.button?.performClick(nil)
                // Remove the menu after it's been displayed
                DispatchQueue.main.async {
                    self.statusItem.menu = nil
                }
            }
        }
    }
    
    func excuteShortcutFlow() {
        var shortcutsFlowName: String {
            UserDefaults.shared.value(for: \.shortcutsFlowName)
        }
        print("shortcutsFlowName \(shortcutsFlowName)")
        excuteFlowByName(shortcutsFlowName)
    }
    
    func excuteFlowByName(_ name: String) {
        let openAISvc = OpenAIService()
        var inputText: String {
            UserDefaults.shared.value(for: \.inputText)
        }
        if let flow = FlowService.shared.findFlowByName(name) {
            // Add your logic for handling the flow selection here
            if flow.prefer == FlowPrefer.clipboard.rawValue {
                if let text = ClipboardService.shared.retrieve(String.self) {
                    self.inputText = text
                }
                print("inputText \(inputText)")
                if inputText.isEmpty {
                    if let image = ScreenshotService.take() {
                        do {
                            let text = try OCRService.shared.recognize(image)
                            self.inputText = text
                        } catch {
                            print("OCR Error: \(error)")
                        }
                    }
                }
            }
            
            if flow.prefer == FlowPrefer.screenshot.rawValue {
                if let image = ScreenshotService.take() {
                    do {
                        let text = try OCRService.shared.recognize(image)
                        self.inputText = text
                    } catch {
                        print("OCR Error: \(error)")
                    }
                }
            }
            
            if inputText.isEmpty {
                outputText = "Input text is empty. You need to provide some input text from the clipboard or take a screenshot."
                return
            }
        
            outputText = ""
            
            // auto open result Popover
            if autoOpenResultPanel {
                showPopover?()
            }
     
            globalRunLoading = true
            setLoadingIcon()
            cancel = try! openAISvc.excuteFlowStream(name: flow.name, input: inputText, callback: { text in
                let section = OpenAIService.handleStreamedData(dataString: text)
                self.outputText += section
                let isDone = OpenAIService.isResDone(dataString: text)
                if isDone {
                    self.globalRunLoading = false
                    self.setNormalIcon()
                    // auto save to clipboard
                    if self.autoSaveToClipboard {
                        try! ClipboardService.shared.save(self.outputText)
                    }
                    // async save history
                    DispatchQueue.main.async {
                        try! HistoryService.shared.create(HistoryDto(name: flow.name, input: self.inputText, result: self.outputText))
                    }
                    return
                }
            })
        }else {
            outputText = "Flow not found"
        }
    }
    
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        guard let flow = sender.representedObject as? Flow else { return }
        let name = flow.name
        homeSelectedFlowName = name
        excuteFlowByName(name)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    deinit {
        notificationToken?.invalidate()
    }
}

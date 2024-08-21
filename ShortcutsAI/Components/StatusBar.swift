//
//  StatusBar.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import SwiftUI

class StatusBar{
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var menu: NSMenu
    private var cancel: (() -> Void)?
    private var cancelMenu: NSMenuItem?
    
    
    // camera.metering.center.weighted
    // wand.and.rays
    // square.3.layers.3d.middle.filled
    private var loadingIcon = "hourglass.bottomhalf.filled"
    private var normalIcon = "wand.and.rays"
    
    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wand.and.rays", accessibilityDescription: nil)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleClick)
        }
        
        loadMenu()
    }
    
    func setNormalStatusButtonIcon(){
        if let button = self.statusItem.button {
            button.image = NSImage(systemSymbolName: "wand.and.rays", accessibilityDescription: nil)
        }
    }
    
    func setProcessingStatusButtonIcon(){
        if let button =  self.statusItem.button {
            button.image = NSImage(systemSymbolName: "hourglass.bottomhalf.filled", accessibilityDescription: nil)
        }
    }
    
    func showMenu() {
        statusItem.menu = menu
    }
    func removeMenu() {
        statusItem.menu = nil
    }
    
    
    func loadMenu() {
        menu.removeAllItems()
        let flowSv = FlowService.shared
        let flows = flowSv.findAll()
        
        // print flows count
        if !flows.isEmpty {
            for flow in flows {
                let menuItem = NSMenuItem()
                menuItem.title = flow.name ?? ""
                menuItem.action = #selector(startFlow(_:))
                menuItem.target = self
                menuItem.representedObject = flow
                menu.addItem(menuItem)
            }
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(getTakeScreenshotMenuItem())
        menu.addItem(getOCRMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(getQuitMenuItem())
    }
    
    
    func startFlowByName(name:String, ocr:Bool = false){
        let appConfig = AppConfigService.shared.get()
        if let flow = FlowService.shared.find(name: name) {
            var input = ""
            if flow.prefer == FlowPrefer.clipboard.rawValue && !ocr {
                if let text =  ClipboardService.shared.retrieve(String.self){
                    input = text
                }
            }
            if input.isEmpty {
                let image = ScreenshotService.take()
                if image == nil {
                    LogService.shared.log(level: .error, message: "Shortchut: Failed to take screenshot")
                    return
                }
              
                let appKey = appConfig?.ocrYoudaoAppKey ?? ""
                let appSecret = appConfig?.ocrYoudaoAppSecret ?? ""
                
                if  appKey.isEmpty || appSecret.isEmpty {
                    LogService.shared.log(level: .error, message: "Shortchut: Please set up OCR API Key and Secret in settings.")
                    return
                }
                let ocrSv = OCRYoudaoService(appKey: appKey, appSecret: appSecret)
                input = ocrSv.takeOCRSync(image: image!)
            }
            if input.isEmpty {
                LogService.shared.log(level: .error, message: "Shortchut: No input found")
                return
            }
            if !AppConfigService.shared.openAISetupOK() {
                LogService.shared.log(level: .error, message: "Shortchut: Please set up OpenAI API Key in settings.")
                return
            }
            setProcessingStatusButtonIcon()
            let cancelMenu = NSMenuItem()
            cancelMenu.title = "Cancel"
            cancelMenu.action = #selector(cancelFlow)
            cancelMenu.target = self
            menu.addItem(cancelMenu)
            self.cancelMenu = cancelMenu
            self.cancel = ExcuteFlowService.excute(name: name, input: input){ text in
                AppConfigService.shared.update(dto: UpdateAppConfigRequest(
                    input: input,
                    output: text
                ))
                self.setNormalStatusButtonIcon()
                if self.menu.items.contains(cancelMenu){
                    self.menu.removeItem(cancelMenu)
                }
                if let ok = appConfig?.autoSaveToClipboard {
                    if !ok {
                        return
                    }
                }
                do {
                    try ClipboardService.shared.save(text)}
                catch {
                    LogService.shared.log(level: .error, message: "Shortchut: Failed to copy to clipboard \(error)")
                }
            }
            
        }else{
            LogService.shared.log(level: .error, message: "Shortchut: Flow not found: \(name)")
        }
    }
    
    
    @objc func startFlow(_ sender: NSButton) {
        let name = sender.title
        startFlowByName(name: name)
    }
    
    
    @objc func handleClick() {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                excuteShortcutFlow()
            } else {
                showMenu()
                statusItem.button?.performClick(nil)
                // Remove the menu after it's been displayed
                DispatchQueue.main.async {
                    self.removeMenu()
                }
            }
        }
    }
    
    private func excuteShortcutFlow(){
        let appConfig = AppConfigService.shared.get()
        let flowName = appConfig?.shortcutFlowName ?? ""
        if flowName.isEmpty {
            LogService.shared.log(level: .error, message: "Shortchut: Please set up shortcut flow in settings.")
            return
        }
        startFlowByName(name: flowName , ocr: true)
    }
    
    private func getQuitMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = "Quit"
        menuItem.action = #selector(quit)
        menuItem.keyEquivalent = "q"
        menuItem.target = self
        return menuItem
    }
    
    private func getTakeScreenshotMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = "Take Screenshot"
        menuItem.action = #selector(takeScreenshot)
        menuItem.keyEquivalent = "o"
        menuItem.target = self
        return menuItem
    }
    
    private func getOCRMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = "OCR Text"
        menuItem.action = #selector(takeOCR)
        menuItem.keyEquivalent = "r"
        menuItem.target = self
        return menuItem
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func takeScreenshot() {
        let image = ScreenshotService.take()
        if image == nil {
            LogService.shared.log(level: .error, message: "Shortchut: Failed to take screenshot")
        }
    }
    
    @objc func takeOCR() {
        let appConfig = AppConfigService.shared.get()
        let appKey = appConfig?.ocrYoudaoAppKey ?? ""
        let appSecret = appConfig?.ocrYoudaoAppSecret ?? ""
        
        if  appKey.isEmpty || appSecret.isEmpty {
            LogService.shared.log(level: .error, message: "Shortchut: Please set up OCR API Key and Secret in settings.")
            return
        }
        
        let image = ScreenshotService.take()
        if image == nil {
            LogService.shared.log(level: .error, message: "Shortchut: Failed to take screenshot")
            return
        }
        setProcessingStatusButtonIcon()
        let ocrSv = OCRYoudaoService(appKey: appKey, appSecret: appSecret)
        let  text = ocrSv.takeOCRSync(image: image!)
        AppConfigService.shared.update(dto: UpdateAppConfigRequest(
            input: text
        ))
        setNormalStatusButtonIcon()
        do {
            try ClipboardService.shared.save(text)}
        catch {
            LogService.shared.log(level: .error, message: "Shortchut: Failed to copy to clipboard \(error)")
        }
    }
    
    @objc func cancelFlow(){
        if let cancel = self.cancel {
            cancel()
            self.cancel = nil
            if let cancelMenu = self.cancelMenu {
                if self.menu.items.contains(cancelMenu){
                    self.menu.removeItem(cancelMenu)
                }
            }
        }
    }
}

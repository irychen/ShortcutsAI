//
//  ShortcutsAIApp.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import SwiftUI

@main
struct ShortcutsAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 600, maxWidth: 600, minHeight: 580, maxHeight: .infinity)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }.windowResizability(.contentSize) // <- 2. Add the restriction here
    }
}

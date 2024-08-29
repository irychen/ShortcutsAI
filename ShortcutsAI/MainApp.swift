
import AppKit
import SwiftUI

@main
struct MainApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, maxWidth: 600, minHeight: 600, maxHeight: .infinity)
                .onAppear {
                    UserDefaults.setupDefaultSettings()
                }
        }.windowStyle(HiddenTitleBarWindowStyle())
            .windowResizability(.contentSize)
    }
}


import AppKit
import SwiftUI

@main
struct MainApp: App {
    @AppStorage(\.appIsInitialized) var appIsInitialized
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, maxWidth: 600, minHeight: 630, maxHeight: .infinity)
                .onAppear {
                    UserDefaults.setupDefaultSettings()
                    if !appIsInitialized {
                        appIsInitialized = !appIsInitialized

                        // init data
                        FlowService.shared.initDefault()
                        print("App initialized.")
                    }
                }
        }.windowStyle(HiddenTitleBarWindowStyle())
            .windowResizability(.contentSize)
    }
}

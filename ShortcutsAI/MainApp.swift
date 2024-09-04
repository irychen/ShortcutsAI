
import AppKit
import SwiftUI


@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(\.appIsInitialized) var appIsInitialized
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .frame(minWidth: 600, maxWidth: 600, minHeight: 630, maxHeight: .infinity)
                .onAppear {
                    UserDefaults.setupDefaultSettings()
                    if !appIsInitialized {
                        appIsInitialized = !appIsInitialized
                        FlowService.shared.initDefault()
                        print("App initialized.")
                    }
                }
        }.windowStyle(HiddenTitleBarWindowStyle())
            .windowResizability(.contentSize)
    }
}


import SwiftUI

struct ContentView: View {

    @AppStorage(\.currentAppTabKey) var currentAppTabKey

    let tabs = [
        TabItem(label: "Home", icon: "house.fill", key: "home", view: AnyView(HomeView())),
        TabItem(label: "Translator", icon: "globe.americas.fill", key: "translator", view: AnyView(TranslatorView())),
        TabItem(label: "Flow", icon: "arrow.up.arrow.down.circle.fill", key: "flow", view: AnyView(FlowView())),
        TabItem(label: "History", icon: "clock.fill", key: "history", view: AnyView(HistoryView())),
        TabItem(label: "Settings", icon: "gearshape.fill", key: "settings", view: AnyView(SettingsView())),
    ]

    var body: some View {
        VStack {
            HStack {
                CurrentView
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial.opacity(0.01))
            CustomTabView(tabs: tabs, currentKey: $currentAppTabKey)
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.04), Color.purple.opacity(0.04)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var CurrentView: AnyView {
        tabs.first { $0.key == currentAppTabKey }?.view ?? AnyView(EmptyView())
    }
}

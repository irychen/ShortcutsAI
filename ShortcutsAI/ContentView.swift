
import SwiftUI

struct ContentView: View {
    @StateUserDefault("currentTabKey", defaultValue: "home")
    private var currentTabKey: String

    let tabs = [
        TabItem(label: "Home", icon: "house.fill", key: "home", view: AnyView(Text("Home Content"))),
        TabItem(label: "Translator", icon: "globe.americas.fill", key: "translator", view: AnyView(Text("Translator Content"))),
        TabItem(label: "Chat", icon: "message.fill", key: "chat", view: AnyView(Text("Chat Content"))),
        TabItem(label: "Flow", icon: "arrow.up.arrow.down.circle.fill", key: "flow", view: AnyView(Text("Flow Content"))),
        TabItem(label: "Prompt", icon: "captions.bubble.fill", key: "prompt", view: AnyView(Text("Prompt Content"))),
        TabItem(label: "Statistics", icon: "chart.bar.xaxis", key: "statistics", view: AnyView(Text("Statistics Content"))),
        TabItem(label: "Settings", icon: "gearshape.fill", key: "settings", view: AnyView(SettingsView())),
    ]

    var body: some View {
        VStack {
            HStack {
                CurrentView
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial.opacity(0.01))
            CustomTabView(tabs: tabs, currentKey: $currentTabKey)
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var CurrentView: AnyView {
        tabs.first { $0.key == currentTabKey }?.view ?? AnyView(EmptyView())
    }
}

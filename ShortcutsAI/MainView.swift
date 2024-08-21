//
//  ContentView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            IndexView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            FlowView()
                .tabItem {
                    Label("Flow", systemImage: "star")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            LogView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet")
                }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity) 
        .onAppear() {
  
        }
    }
}

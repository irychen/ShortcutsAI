//
//  SettingsView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/30.
//

import AppKit
import Foundation
import RealmSwift
import SwiftUI

struct SettingsView: View {
    class Settings: ObservableObject {
        // ------------ section of OpenAI Service ------------
        @AppStorage(\.openAIKey) var openAIKey: String
        @AppStorage(\.openAIBaseURL) var openAIBaseURL: String
        @AppStorage(\.defaultFlowModel) var defaultFlowModel: String
        @AppStorage(\.openAImodels) var openAIModels: [String]

        // ------------ section of OCR Service ------------
        @AppStorage(\.selectedOCRService) var selectedOCRService: String
        @AppStorage(\.ocrYoudaoAppKey) var ocrYoudaoAppKey: String
        @AppStorage(\.ocrYoudaoAppSecret) var ocrYoudaoAppSecret: String
        @AppStorage(\.ocrSpaceAPIKey) var ocrSpaceAPIKey: String
        @AppStorage(\.ocrSpacePreferredLanguage) var ocrSpacePreferredLanguage: String

        // ------------ section of Other ------------
        @AppStorage(\.shortcutsFlowName) var shortcutsFlowName: String
        @AppStorage(\.autoSaveToClipboard) var autoSaveToClipboard: Bool
        @AppStorage(\.autoStartOnBoot) var autoStartOnBoot: Bool
        @AppStorage(\.autoOpenResultPanel) var autoOpenResultPanel: Bool

        init() {}
    }

    @State private var showAlert = false
    @StateObject var settings = Settings()

    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                    .background(Color.white.opacity(0.001))
                    .font(.system(size: 18, weight: .bold))
            }
            .draggable()
            Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 2).padding(.horizontal, 0).padding(.vertical, 0)
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.vertical) {
                    VStack {
                        Form {
                            Section(header: Text("OpenAI Service").bold()) {
                                CustomTextField(label: "API Key", text: $settings.openAIKey, placeholder: "OpenAI API Key", password: true)
                                HStack {
                                    CustomTextField(label: "Base URL", text: $settings.openAIBaseURL, placeholder: "Like https://api.openai.com")
                                    Button(action: {}) {
                                        Text("Test Connection").frame(width: 120)
                                    }
                                }

                                HStack {
                                    Picker("Default Flow Model", selection: $settings.defaultFlowModel) {
                                        ForEach(
                                            settings.openAIModels.map { SelectOption(value: $0, label: $0) },
                                            id: \.value
                                        ) { option in
                                            Text(option.label).tag(option.value)
                                        }
                                    }
                                }
                            }

                            Section(header: Text("OCR Service").bold().padding(.top, 10)) {
                                Picker("Service Provider", selection: $settings.selectedOCRService) {
                                    ForEach(OCRServiceOptions) { option in
                                        Text(option.label).tag(option.value)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())

                                Group {
                                    if settings.selectedOCRService == "youdao" {
                                        CustomTextField(label: "App Key", text: $settings.ocrYoudaoAppKey, placeholder: "App Key", password: true)
                                        CustomTextField(label: "App Secret", text: $settings.ocrYoudaoAppSecret, placeholder: "App Secret", password: true)
                                        Link("Click here to get youdao OCR app Key and Secret", destination: URL(string: "https://ai.youdao.com")!).font(.caption)
                                    } else if settings.selectedOCRService == "ocrspace" {
                                        Picker("Language", selection: $settings.ocrSpacePreferredLanguage) {
                                            ForEach(
                                                languageOptions,
                                                id: \.value
                                            ) { option in
                                                Text(option.label).tag(option.value)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        CustomTextField(label: "API Key", text: $settings.ocrSpaceAPIKey, placeholder: "API Key", password: true)
                                        Link("Click here to get ocr.space API Key", destination: URL(string: "https://ocr.space/ocrapi/freekey")!).font(.caption)

                                    } else {
                                        Text("No Service Selected")
                                    }
                                }
                            }

                            Section(header: Text("Other").bold().padding(.top, 10)) {
                                Picker("Shortcut Flow", selection: $settings.shortcutsFlowName) {
                                    ForEach(
                                        [
                                            SelectOption(value: "Translate", label: "Translate"),
                                            SelectOption(value: "OCR", label: "OCR"),
                                        ],
                                        id: \.value
                                    ) { option in
                                        Text(option.label).tag(option.value)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                Text("This flow is for statusbar right click screenshot OCR.").font(.caption)

                                Toggle(isOn: $settings.autoSaveToClipboard) {
                                    Text("Auto save result to clipboard")
                                }

                                Toggle(isOn: $settings.autoOpenResultPanel) {
                                    Text("Open result panel after running flow from status bar")
                                }

                                Toggle(isOn: $settings.autoStartOnBoot) {
                                    Text("Auto start on boot")
                                }
                            }

                            HStack(alignment: .center) {
                                Button(action: {
                                    showAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("Clean Data")
                                    }
                                    .font(.headline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .foregroundColor(.white)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.red.opacity(0.9), Color.pink.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                    )
//                                      .shadow(color: Color.red.opacity(0.3), radius: 3, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle())
                                .alert(isPresented: $showAlert) {
                                    Alert(
                                        title: Text("Warning"),
                                        message: Text("This action will delete all data. Are you sure you want to proceed?"),
                                        primaryButton: .destructive(Text("Clean")) {
                                            cleanData()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }.padding(.top, 10)
                        }
                    }.padding(.horizontal, 20).padding(.vertical, 14)
                }
            }
        }
    }

    func cleanData() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
}

struct CustomTextField: View {
    var label: String
    @Binding var text: String
    var placeholder: String?
    var password: Bool = false
    var disabled: Bool = false

    var body: some View {
        Group {
            if password {
                SecureField(label, text: $text, prompt: Text(placeholder ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
            } else {
                TextField(label, text: $text, prompt: Text(placeholder ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
            }
        }
        .cornerRadius(5)
        .disabled(disabled)
    }
}

struct DraggableModifier: ViewModifier {
    @State private var isDragging = false

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { _ in
                        if !isDragging {
                            isDragging = true
                            if let currentEvent = NSApplication.shared.currentEvent {
                                NSApp.mainWindow?.performDrag(with: currentEvent)
                            }
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}

extension View {
    func draggable() -> some View {
        modifier(DraggableModifier())
    }
}

//
//  TranslatorView.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/8.
//

import Foundation
import RealmSwift
import SwiftUI

var languages = [
    SelectOption(value: "auto", label: "Auto"),
    SelectOption(value: "Chinese", label: "Chinese"),
    SelectOption(value: "Chinese (Simplified)", label: "Chinese (Simplified)"),
    SelectOption(value: "Chinese (Traditional)", label: "Chinese (Traditional)"),
    SelectOption(value: "English", label: "English"),
    SelectOption(value: "English (UK)", label: "English (UK)"),
    SelectOption(value: "English (US)", label: "English (US)"),
    SelectOption(value: "French", label: "French"),
    SelectOption(value: "German", label: "German"),
    SelectOption(value: "Italian", label: "Italian"),
    SelectOption(value: "Japanese", label: "Japanese"),
    SelectOption(value: "Korean", label: "Korean"),
    SelectOption(value: "Portuguese", label: "Portuguese"),
    SelectOption(value: "Russian", label: "Russian"),
    SelectOption(value: "Spanish", label: "Spanish"),
    SelectOption(value: "Arabic", label: "Arabic"),
    SelectOption(value: "Dutch", label: "Dutch"),
    SelectOption(value: "Greek", label: "Greek"),
]

var targets = languages.filter { $0.value != "auto" }

struct TranslatorView: View {
    @AppStorage(\.openAImodels) var openAIModels: [String]
    @AppStorage(\.translateFrom) private var translateFrom
    @AppStorage(\.translateTo) private var translateTo
    @AppStorage(\.translateInputText) private var translateInputText
    @AppStorage(\.translateOutputText) private var translateOutputText
    @AppStorage(\.translateModel) private var translateModel
    @AppStorage(\.translateTemperature) private var translateTemperature

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    @State private var cancel: (() -> Void)?
    @State private var loading: Bool = false

    func getPrompt() -> String {
        if translateFrom == "auto" {
            return """
            # You are an expert in translation, please help me translate the following text to \(translateTo)
            1. keep the original meaning.
            2. The translation should be accurate and fluent.
            3. The translation should be natural and grammatically correct.
            """
        } else {
            return """
            # You are an expert in translation, please help me translate the following text written in \(translateFrom) to \(translateTo)
            1. keep the original meaning.
            2. The translation should be accurate and fluent.
            3. The translation should be natural and grammatically correct.
            """
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Translator")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                    .background(Color.white.opacity(0.001))
                    .font(.system(size: 18, weight: .bold))
            }
            .draggable()

            HStack {
                VStack(alignment: .leading) {
                    Picker("From ", selection: $translateFrom) {
                        ForEach(languages) { language in
                            Text(language.label).tag(language.value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Spacer()

                VStack(alignment: .leading) {
                    Picker("To", selection: $translateTo) {
                        ForEach(targets) { language in
                            Text(language.label).tag(language.value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Spacer()
                Button(action: {
                    translateText()
                }) {
                    Text(loading ? "Translating..." : "Translate")
                }.buttonStyle(NormalButtonStyle(isPrimary: true))
            }
            .padding(.vertical, 10).padding(.horizontal, 20)

            HStack {
                Picker("Model", selection: $translateModel) {
                    ForEach(
                        openAIModels.map { SelectOption(value: $0, label: $0) },
                        id: \.value
                    ) { option in
                        Text(option.label).tag(option.value)
                    }
                }.frame(width: 200)
                Text("Temperature: \(translateTemperature, specifier: "%.1f")").frame(width: 120)
                Slider(value: Binding(
                    get: {
                        translateTemperature
                    },
                    set: { newValue in
                        translateTemperature = round(newValue * 10) / 10
                    }
                ), in: 0 ... 1)

            }.padding(.bottom, 10).padding(.horizontal, 20)
            AutoresizingTextEditor(
                text: $translateInputText,
                font: .systemFont(ofSize: 12),
                isEditable: true,
                maxHeight: 80,
                lineSpacing: 4,
                placeholder: "input text here ..."
            ) {}.padding(8).background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.12))
                }
            ).padding(.horizontal, 20)
            HStack {
                Space(direction: .horizontal) {
                    Button(action: {
                        takeOCR()
                    }) {
                        Text("Screen OCR")
                    }.buttonStyle(NormalButtonStyle(isPrimary: true))
                    Button(action: {
                        copyToClipboard(translateOutputText)
                    }) {
                        Text("Copy Result")
                    }.buttonStyle(NormalButtonStyle())
                    Button(action: {
                        // do something
                        translateInputText = ""
                        translateOutputText = ""
                    }) {
                        Text("Clear")
                    }.buttonStyle(NormalButtonStyle())
                }
            }.padding(.vertical, 10)
            ScrollView(.vertical) {
                ThemedMarkdownText(translateOutputText,
                                   fontSize: 13,
                                   codeFont: .monospaced(.body)(),
                                   wrapCode: true).padding(12).frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                }
            ).padding(.horizontal, 20)
        }.alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func translateText() {
        translateOutputText = ""
        if translateInputText.isEmpty {
            translateOutputText = "Please input text to translate"
            return
        }
        let prompt = getPrompt()
        var data = OpenAICompletionRequest(
            model: translateModel,
            messages: [],
            temperature: Float(translateTemperature)
        )
        data.messages.append(OpenAIMessage(
            role: OpenAIRole.system,
            content: prompt
        ))
        data.messages.append(OpenAIMessage(
            role: OpenAIRole.user,
            content: translateInputText
        ))
        let openAISvc = OpenAIService()

        do {
            loading = true
            try openAISvc.stream(request: data)
            cancel = openAISvc.stopListening
            openAISvc.onDataReceived = { text in
                let section = OpenAIService.handleStreamedData(dataString: text)
                self.translateOutputText += section
                let isDone = OpenAIService.isResDone(dataString: text)
                if isDone {
                    self.loading = false
                    DispatchQueue.main.async {
                        try! HistoryService.shared.create(HistoryDto(name: "Translator", input: self.translateInputText, result: self.translateOutputText))
                    }
                    return
                }
            }
        } catch {
            alertTitle = "Translate Error"
            alertMessage = "Translate Error: \(error)"
            showAlert = true
        }
    }

    func copyToClipboard(_ text: String) {
        try! ClipboardService.shared.save(text)
    }

    func takeOCR() {
        let ocrSvc = OCRService.shared
        if let image = ScreenshotService.take() {
            do {
                let text = try ocrSvc.recognize(image)
                translateInputText = text
                DispatchQueue.main.async {
                    try! HistoryService.shared.create(HistoryDto(name: "OCR Text", input: "", result: text))
                }
            } catch {
                alertTitle = "OCR Error"
                alertMessage = "OCR Error: \(error)"
                showAlert = true
            }
        }
    }
}

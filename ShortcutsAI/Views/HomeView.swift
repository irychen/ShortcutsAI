//
//  HomeView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/30.
//

import Foundation
import MarkdownUI
import RealmSwift
import SwiftUI

struct HomeView: View {
    @AppStorage(\.inputText) private var inputText
    @AppStorage(\.outputText) private var outputText
    @AppStorage(\.homeSelectedFlowName) private var homeSelectedFlowName
    @ObservedResults(Flow.self) var flows

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    @State private var cancel: (() -> Void)?
    @State private var loading: Bool = false

    func takeOCR() {
        // do something
        print("Take OCR")
        let ocrSvc = OCRService.shared
        if let image = ScreenshotService.take() {
            do {
                let text = try ocrSvc.recognize(image)
                inputText = text
                // save History
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

    func excuteStreamFlow() {
        outputText = ""
        let openAISvc = OpenAIService()
        loading = true
        do {
            cancel = try openAISvc.excuteFlowStream(name: homeSelectedFlowName, input: inputText, callback: { text in
                let section = OpenAIService.handleStreamedData(dataString: text)
                self.outputText += section
                let isDone = OpenAIService.isResDone(dataString: text)
                if isDone {
                    self.loading = false

                    DispatchQueue.main.async {
                        try! HistoryService.shared.create(HistoryDto(name: self.homeSelectedFlowName, input: self.inputText, result: self.outputText))
                    }
                    return
                }
            })
        } catch let error as OpenAIServiceError {
            alertTitle = "Flow Error"
            alertMessage = "Flow Error: \(error.description)"
            showAlert = true
        } catch {
            alertTitle = "Flow Error"
            alertMessage = "Flow Error: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func stopListening() {
        cancel?()
        loading = false
    }

    func clearAll() {
        inputText = ""
        outputText = ""
    }

    func copyToClipboard(_ text: String) {
        try! ClipboardService.shared.save(text)
    }

    var body: some View {
        VStack {
            HStack {
                Text("Shortcuts AI")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                    .background(Color.white.opacity(0.001))
                    .font(.system(size: 18, weight: .bold))
            }
            .draggable()
            AutoresizingTextEditor(
                text: $inputText,
                font: .systemFont(ofSize: 12),
                isEditable: true,
                maxHeight: 80,
                lineSpacing: 4,
                placeholder: "Enter your text here or OCR result will be displayed here."
            ) {}.padding(8).background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.12))
                }
            ).padding(.horizontal, 20)
            HStack {
                Space(direction: .horizontal) {
                    Button(action: takeOCR) {
                        Text("Screen OCR")
                    }.buttonStyle(NormalButtonStyle(isPrimary: true))
                    Button(action: {
                        copyToClipboard(inputText)
                    }) {
                        Text("Copy")
                    }.buttonStyle(NormalButtonStyle())
                    Button(action: {
                        inputText = ""
                    }) {
                        Text("Clear")
                    }.buttonStyle(NormalButtonStyle())
                }
            }.padding(.vertical, 10)
            Picker("Select Flow", selection: $homeSelectedFlowName) {
                ForEach(
                    flows.map { SelectOption(value: $0.name, label: $0.name) },
                    id: \.value
                ) { option in
                    Text(option.label).tag(option.value)
                }
            }.padding(.horizontal, 20).pickerStyle(MenuPickerStyle()).padding(.bottom, 10)
            ScrollView(.vertical) {
                ThemedMarkdownText(outputText,
                                   fontSize: 14,
                                   codeFont: .monospaced(.body)(),
                                   wrapCode: true)
                    .padding(12).frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                }
            ).padding(.horizontal, 20)
            HStack {
                Space(direction: .horizontal) {
                    Button(action: {
                        excuteStreamFlow()
                    }) {
                        Text(loading ? "Loading..." : "Run Flow")
                    }.buttonStyle(NormalButtonStyle(isPrimary: true)).disabled(loading)
                    Button(action: {
                        copyToClipboard(outputText)
                    }) {
                        Text("Copy")
                    }.buttonStyle(NormalButtonStyle())
                    Button(action: {
                        outputText = ""
                    }) {
                        Text("Clear")
                    }.buttonStyle(NormalButtonStyle())
                    Button(action: {
                        clearAll()
                    }) {
                        Text("Clear All")
                    }.buttonStyle(NormalButtonStyle())
                    // Clear Clipboard
                    Button(action: {
                        ClipboardService.shared.clear()
                        try! ClipboardService.shared.save("")
                    }) {
                        Text("Clear Clipboard")
                    }.buttonStyle(NormalButtonStyle(isDanger: true))

                    Button(action: {
                        stopListening()
                    }) {
                        Text("Stop")
                    }.buttonStyle(NormalButtonStyle(isDanger: true, isDisabled: !loading))
                }
            }.padding(.top, 10)
            Spacer()
        }.alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

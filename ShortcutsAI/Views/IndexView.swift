//
//  IndexView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import SwiftUI

struct IndexView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Flow.order, ascending: true)],
        animation: .default)
    private var flows: FetchedResults<Flow>
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    @State private var input: String = ""
    @State private var output: String = ""
    

    @State private var selectedFlowIndex: Int = 0
    
    @State private var cancel: (() -> Void)?
    @State private var loading: Bool = false
    
    var body: some View {
        VStack{
            
            // title OCR Result
            Text("OCR Result")
                .font(.system(size: 16))
                .padding(.top, 10)
            
            // Text Field for OCR Result
            HStack{
                TextEditor(text: $input)
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 120)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
            }.padding([.horizontal], 10)
            
            HStack{
                Space(direction: .horizontal, content: (
                    {
                        Button(action: {
                            takeOCR()
                        }) {
                            Text("Screen OCR")
                        }
                        Button(action: {
                            copyInput()
                        }) {
                            Text("Copy")
                        }
                        Button(action: {
                            // do something
                        }) {
                            Text("Translate")
                        }
                        Button(action: {
                            // do something
                        }) {
                            Text("Summarize")
                        }
                        Button(action: {
                            // do something
                            clearInput()
                        }) {
                            Text("Clear")
                        }
                    }
                ))
            }.padding([.top,.bottom], 10)
            
            Picker("Select a Flow", selection: $selectedFlowIndex) {
                ForEach(flows.indices, id: \.self) { index in
                    Text(flows[index].name ?? "select").tag(index)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding([.horizontal], 10)
            .onChange(of: selectedFlowIndex) { newValue in
                let selectedFlow = flows[newValue]
                if let name = selectedFlow.name {
                    let appConfigSvc = AppConfigService.shared
                    appConfigSvc.update(dto: UpdateAppConfigRequest(
                        indexFlowName: name
                    ))
                }
            }
            
            HStack{
                TextEditor(text: $output)
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 150)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
            }.padding([.horizontal], 10)
            
            HStack{
                Space(direction: .horizontal, content: (
                    {
                        Button(action: {
                            excuteFlow()
                        }) {
                            Text(loading ? "Excuting...":"Excute Flow").padding([.horizontal],10).padding([.vertical],1.8)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#9C99FA"), Color(hex: "#5958D6")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                .cornerRadius(6)
                                .shadow(color: Color(hex: "#33333322"), radius: 1, x: 0, y: 0)
                        }.buttonStyle(.plain)
                        Button(action: {
                            copyOutput()
                        }) {
                            Text("Copy")
                        }
                        
                        Button(action: {
                            clearOutput()
                        }) {
                            Text("Clear")
                        }
                        
                        Button(action: {
                            clearAll()
                        }) {
                            Text("Clear All")
                        }
                        
                        Button(action: {
                            clearClipboard()
                        }) {
                            Text("Clear Clipboard")
                        }
                        
                        // stop
                        Button(action: {
                            cancel?()
                            loading = false
                        }) {
                            Text("Stop")
                        }.disabled(!loading)
                    }
                ))
            }.padding([.top,.bottom], 10)
            Spacer(minLength: 0)
            
        }
        .onAppear{
            loadFlows()
            loadConfig()
        }.alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func saveToConfig(){
       AppConfigService.shared.update(dto: UpdateAppConfigRequest(
        input: input,
        output: output
       ))
    }
    
    func loadConfig(){
        let appConfig = AppConfigService.shared.get()
        output = appConfig?.output ?? ""
        input = appConfig?.input ?? ""
    }
    
    func loadFlows(){
        let flows = FlowService.shared.findAll()
        if !flows.isEmpty {
            let appConfig = AppConfigService.shared.get()
            if let indexFlowName = appConfig?.indexFlowName {
                // get flow index by name
                for (index, flow) in flows.enumerated() {
                    if flow.name == indexFlowName {
                        selectedFlowIndex = index
                        break
                    }
                }
            }
        }else{
            selectedFlowIndex = 0
        }
    }
    
    func takeOCR(){
        let appConfig = AppConfigService.shared.get()
        let appKey = appConfig?.ocrYoudaoAppKey ?? ""
        let appSecret = appConfig?.ocrYoudaoAppSecret ?? ""
        
        if  appKey.isEmpty || appSecret.isEmpty {
            alertTitle = "OCR Config Error"
            alertMessage = "Please set up OCR API Key and Secret in settings."
            showAlert = true
            return
        }
        
        let image = ScreenshotService.take()
        if image == nil {
            alertTitle = "Screenshot Error"
            alertMessage = "Failed to take screenshot"
            showAlert = true
            return
        }
        
        let ocrSv = OCRYoudaoService(appKey: appKey, appSecret: appSecret)
        
        input = ocrSv.takeOCRSync(image: image!)
        
        copyInput()
    }
    
    func clearInput(){
        input = ""
        AppConfigService.shared.update(dto: UpdateAppConfigRequest(
            input: ""
        ))
    }
    
    func clearOutput(){
        output = ""
        AppConfigService.shared.update(dto: UpdateAppConfigRequest(
            output: ""
        ))
    }
    
    func copyInput(){
        let clipboardSv = ClipboardService.shared
        do {
            try clipboardSv.save(input)
        } catch {
            alertTitle = "Copy Error"
            alertMessage = "Failed to copy to clipboard \(error)"
            showAlert = true
        }
    }
    
    func copyOutput(){
        let clipboardSv = ClipboardService.shared
        do {
            try clipboardSv.save(output)
        } catch {
            alertTitle = "Copy Error"
            alertMessage = "Failed to copy to clipboard \(error)"
            showAlert = true
        }
    }
    
    func clearAll(){
        input = ""
        output = ""
        AppConfigService.shared.update(dto: UpdateAppConfigRequest(
            input: "",
            output: ""
        ))
    }
    
    func excuteFlow(){
        if input.isEmpty {
            alertTitle = "Error"
            alertMessage = "Please input text first."
            showAlert = true
            return
        }
        
        let flow = flows[selectedFlowIndex]
        
        if !AppConfigService.shared.openAISetupOK() {
            alertTitle = "Error"
            alertMessage = "Please set up OpenAI API Key in settings."
            showAlert = true
            return
        }
        output = ""
        loading = true
        let cancel =  ExcuteFlowService.excuteStream(name: flow.name!, input: input) { text in
            let setion = OpenAIService.handleStreamedData(dataString: text)
            let isDone = OpenAIService.isResDone(dataString: text)
            if isDone {
                self.loading = false
                return
            }
            output += setion
        }
        self.cancel = cancel
    }
    
    func clearClipboard(){
        ClipboardService.shared.clear()
    }
}

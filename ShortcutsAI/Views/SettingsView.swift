//
//  SettingsView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Flow.order, ascending: true)],
        animation: .default)
    private var flows: FetchedResults<Flow>
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    @State var ocrYoudaoAppKey: String = ""
    @State var ocrYoudaoAppSecret: String = ""
    
    @State var openAIBaseURL: String = ""
    @State var openAIKey: String = ""
    @State var model: String = ""

    @State var autoSaveToClipboard: Bool = false
    @State var autoStartOnBoot: Bool = false
    @State var shortcutFlowName: String = ""
    
    @State private var selectedFlowIndex: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.title)
                .padding([.top,.leading], 10)
            
            Form {
                Section(header: Text("OpenAI").bold()) {
                    CustomTextField(label: "Model", text: $model)
                    CustomTextField(label: "Base URL", text: $openAIBaseURL)
                    CustomTextField(label: "API Key", text: $openAIKey, password: true)
                }
                
                Section(header: Text("Youdao OCR").bold().padding(.top, 10) ) {
                    CustomTextField(label: "App Key", text: $ocrYoudaoAppKey,password: true)
                    CustomTextField(label: "App Secret", text: $ocrYoudaoAppSecret,password: true)
                    Link("Click here to get Youdao OCR API Key and Secret", destination: URL(string: "https://ai.youdao.com")!).font(.caption)
                }
                
                Section(header: Text("Other").bold().padding(.top, 10) ) {
                    Picker("Defalut AI Flow", selection: $selectedFlowIndex) {
                        ForEach(flows.indices, id: \.self) { index in
                            Text(flows[index].name ?? "select").tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding([.horizontal], 10)
                    Text("This flow is for statusbar right click screenshot OCR.").font(.caption)
                    
                    // auto_save_to_clipboard
                    Toggle(isOn: $autoSaveToClipboard) {
                        Text("Auto Save to Clipboard")
                    }
                    
                    // auto_start_on_boot
                    Toggle(isOn: $autoStartOnBoot) {
                        Text("Auto Start on Boot")
                    }
                }
                
            }.padding()
            
            HStack(alignment: .center,content: ({
                Spacer(minLength: 0)
                Space(direction:.horizontal, content: ({
                    Button(action: {
                        save()
                    }) {
                        Text("Save Settings")
                            .font(.custom("Arial", fixedSize: 14))
                            .padding([.top, .bottom], 5)
                            .padding([.leading, .trailing], 20)
                    }
                    
                    .buttonStyle(PrimaryButtonStyle())
                    .padding([.leading, .trailing, .bottom], 10)
                    .shadow(color: Color(hex: "#33333333"), radius: 2, x: 0, y: 0)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Success"), message: Text("Settings saved successfully"), dismissButton: .default(Text("OK")))
                    }
                    Button(action: {
                        clearAndQuit()
                    }) {
                        Text("Clean All Data and Quit")
                            .font(.custom("Arial", fixedSize: 14))
                            .padding([.top, .bottom], 5)
                            .padding([.leading, .trailing], 20)
                    }
                    .buttonStyle(DangerButtonStyle())
                    .padding([.leading, .trailing, .bottom], 10)
                    .shadow(color: Color(hex: "#33333333"), radius: 2, x: 0, y: 0)
                }))
                Spacer(minLength: 0)
            }))
            Spacer(minLength: 0)
        }.padding(.bottom, 20).onAppear {
                loadAppConfig()
                loadFlows()
            }.alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
    }
    
    func loadFlows(){
        let flows = FlowService.shared.findAll()
        if !flows.isEmpty {
            let appConfig = AppConfigService.shared.get()
            if let shortcutFlowName = appConfig?.shortcutFlowName {
                // get flow index by name
                for (index, flow) in flows.enumerated() {
                    if flow.name == shortcutFlowName {
                        selectedFlowIndex = index
                        break
                    }
                }
            }
        }else{
            selectedFlowIndex = 0
        }
    }
    
    func  loadAppConfig(){
        let appConfig = AppConfigService.shared.get()
        autoSaveToClipboard = appConfig?.autoSaveToClipboard ?? false
        autoStartOnBoot = appConfig?.autoStartOnBoot ?? false
        
        shortcutFlowName = appConfig?.shortcutFlowName ?? ""
        
        ocrYoudaoAppKey = appConfig?.ocrYoudaoAppKey ?? ""
        ocrYoudaoAppSecret = appConfig?.ocrYoudaoAppSecret ?? ""
        
        openAIBaseURL = appConfig?.openAIBaseURL ?? ""
        openAIKey = appConfig?.openAIKey ?? ""
        model = appConfig?.model ?? ""
        
    }
    
    func save(){
        let appConfigSv = AppConfigService.shared
        appConfigSv.update(dto: UpdateAppConfigRequest(
            shortcutFlowName: flows[selectedFlowIndex].name,
            openAIBaseURL: openAIBaseURL,
            openAIKey: openAIKey,
            model: model,
            ocrYoudaoAppKey: ocrYoudaoAppKey,
            ocrYoudaoAppSecret: ocrYoudaoAppSecret,
            autoSaveToClipboard: autoSaveToClipboard,
            autoStartOnBoot: autoStartOnBoot
        ))
        let loginItemsSv = LoginItemsService.shared
        if autoStartOnBoot {
            if loginItemsSv.isInLoginItems() == false {
                loginItemsSv.addToLoginItems()
            }
        }else{
            if loginItemsSv.isInLoginItems() {
                loginItemsSv.removeFromLoginItems()
            }
        }
        
        alertTitle = "Success"
        alertMessage = "Settings saved successfully"
        showAlert = true
    }
    
    func clearAndQuit(){
        // clear all data
        FlowService.shared.clearAll()
        AppConfigService.shared.clear()
        // quit
        NSApplication.shared.terminate(self)
    }
}

struct CustomTextField: View {
    var label: String
    @Binding var text: String
    var password: Bool = false
    var disabled: Bool = false
    
    var body: some View {
        Group {
            if password {
                SecureField(label, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(label, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .cornerRadius(5)
        .disabled(disabled)  // 应用 disabled 状态
    }
}


// custom button style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        // #444
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#9C99FA"), Color(hex: "#5958D6")]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            .foregroundColor(.white)
            .cornerRadius(4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 按下时缩放效果
    }
}


struct DangerButtonStyle:ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        // #444
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#E26285"), Color(hex: "#E50012")]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            .foregroundColor(.white)
            .cornerRadius(4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 按下时缩放效果
    }
}

struct DefaultButtonStyle:ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        // #444
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#B99ED8"), Color(hex: "#0B7EF2")]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            .foregroundColor(.white)
            .cornerRadius(4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 按下时缩放效果
    }
}

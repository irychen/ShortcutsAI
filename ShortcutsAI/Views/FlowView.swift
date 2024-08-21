//
//  FlowView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import SwiftUI

struct FlowView: View {
    @State private var flows = [Flow]()
    @State private var showModal = false
    @State private var modalType = "create"
    @State private var currentFlowName = ""
    
    var body: some View {
        VStack {
            HStack(alignment: .center, content: {
                
                
                Text("AI Flow")
                    .font(.system(size: 16))
                    .padding(.top, 10)
                Spacer(minLength: 0)
                Button(action: {
                    openCreateModal()
                }) {
                    Text("Create AI Flow").padding([.horizontal],10).padding([.vertical],1.8)
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
            }).padding([.horizontal], 10)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(flows, id: \.id) { flow in
                        HStack {
                            Text(flow.name ?? "")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(flow.prompt ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openEditModal(name: flow.name ?? "")
                        }
                    }
                }.padding([.vertical], 10)
            }
            .background(Color(.windowBackgroundColor))
            
            Spacer(minLength: 0)
        }.onAppear{
            loadFlows()
        }.sheet(isPresented: $showModal) {
            ModalView(showModal: $showModal , modalType: $modalType, name: $currentFlowName)
        }.onChange(of: showModal) { newValue in
            if !newValue {
                loadFlows()
            }
        }
    }
    
    func openEditModal(name: String){
        modalType = "edit"
        currentFlowName = name
        showModal = true
    }
    
    func openCreateModal(){
        modalType = "create"
        currentFlowName = ""
        showModal = true
    }
    
    func loadFlows(){
        flows = FlowService.shared.findAll()
    }
}


struct ModalView: View {
    @Binding var showModal: Bool
    @Binding var modalType: String
    @Binding var name: String
    
    @State private var innerName = ""
    @State private var model = ""
    @State private var prompt = ""
    @State private var fixed = false
    @State private var prefer:String = FlowPrefer.clipboard.rawValue
    @State private var temperature:Float = 0
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    private var previousName = ""
    
    init(showModal: Binding<Bool>, modalType: Binding<String>, name: Binding<String>){
        self._showModal = showModal
        self._modalType = modalType
        self._name = name
    }
    
    var body: some View {
        VStack {
            Text( modalType == "create" ? "Create Flow" : "Edit Flow")
                .font(.system(size: 16) .bold())
            Form {
                Text("Name")
                    .font(.system(size: 14) .bold())
                    .padding(.top, 6)
                CustomTextField(label: "", text: $innerName, disabled: modalType == "edit")
                // prompt TextField
                Text("Prompt")
                    .font(.system(size: 14) .bold())
                    .padding(.top, 6)
                TextEditor(text: $prompt)
                    .font(.system(size: 14))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
                    .cornerRadius(8)
                
                // fixed Radio
                Toggle(isOn: $fixed) {
                    Text("fixed at statusbar menu")
                }
                
                // prefer Select
                Text("Prefer")
                    .font(.system(size: 14) .bold())
                    .padding(.top, 6)
                Picker("", selection: $prefer) {
                    ForEach(FlowPrefer.allCases, id: \.rawValue) { prefer in
                        Text(prefer.rawValue).tag(prefer.rawValue)
                    }
                }
                
                // model TextField
                Text("Model")
                    .font(.system(size: 14) .bold())
                    .padding(.top, 10)
                CustomTextField(label: "", text: $model)
                
                // temperature float number
                HStack{
                    Text("Temperature")
                        .font(.system(size: 14) .bold())
                    Text("\(temperature, specifier: "%.1f")")
                        .font(.system(size: 14))
                
                     
                }   .padding(.top, 6)
            
                Slider(value: Binding(
                            get: {
                                self.temperature
                            },
                            set: { newValue in
                                self.temperature = round(newValue * 10) / 10
                            }
                        ), in: 0...1)
                
            }
            
          HStack(alignment: .center,content: ({
                // close or create/save button
                Spacer(minLength: 0)
                Button(action: {
                    showModal = false
                }) {
                    Text("Close")
                        .font(.system(size: 14))
                        .padding([.top, .bottom], 5)
                }
    
                Button(action: {
                    if modalType == "create" {
                        create()
                    } else {
                        save()
                    }
                }) {
                    Text(modalType == "create" ? "Create" : "Save")
                        .font(.system(size: 14))
                        .padding([.top, .bottom], 5)
                }
                
                if modalType == "edit" {
                    Button(action: {
                        deleteFlow()
                     
                    }) {
                        Text("Delete")
                            .font(.system(size: 14))
                            .padding([.top, .bottom], 5)
                    }
                }
              
                Spacer(minLength: 0)
                
          })).padding([.top, .bottom], 10)
            Spacer(minLength: 0)
        }
        .onAppear{
            initFlow()
        }.alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .frame(width: 480, height: 500).padding()
    }
    
    
    func initFlow(){
        let flow = FlowService.shared.find(name: name)
        let appConfig = AppConfigService.shared.get()
        innerName = flow?.name ?? ""
        model = flow?.model ?? appConfig?.model ?? "gpt-4o-mini"
        prompt = flow?.prompt ?? ""
        fixed = flow?.fixed ?? true
        prefer = flow?.prefer ?? FlowPrefer.clipboard.rawValue
        temperature = flow?.temperature ?? 1.0
    }
    
    func valid() -> Bool{
        let pass = false
        if innerName.isEmpty {
            alertTitle = "Error"
            alertMessage = "Name cannot be empty"
            showAlert = true
            return pass
        }
        if prompt.isEmpty {
            alertTitle = "Error"
            alertMessage = "Prompt cannot be empty"
            showAlert = true
            return pass
        }
        if model.isEmpty {
            alertTitle = "Error"
            alertMessage = "Model cannot be empty"
            showAlert = true
            return pass
        }
        return true
    }
    
    
    func save(){
        if valid() {
            if  FlowService.shared.find(name: innerName) != nil && innerName != name {
                alertTitle = "Error"
                alertMessage = "Name already exists"
                showAlert = true
                return
            }
            
            let updateDto = UpdateFlowDTO(
                name: innerName,
                prompt: prompt,
                fixed: fixed,
                prefer: FlowPrefer(rawValue: prefer),
                model: model,
                temperature: temperature
            )
            do{
                try FlowService.shared.update(targetName: name, dto: updateDto)
                showModal = false
            } catch {
                alertTitle = "Error"
                alertMessage = "Failed to save flow"
                showAlert = true
            }
        }
    }

    func deleteFlow(){
        do{
            try  FlowService.shared.delete(name: name)
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to delete flow"
            showAlert = true
        }
        showModal = false
    }
    
    func create(){
        if valid() {
            
            if  FlowService.shared.find(name: innerName) != nil {
                alertTitle = "Error"
                alertMessage = "Name already exists"
                showAlert = true
                return
            }
        
            let createDto = CreateFlowDTO(
                name: innerName,
                prompt: prompt,
                fixed: fixed,
                prefer: FlowPrefer(rawValue: prefer),
                model: model,
                temperature: temperature
            )
            do{
                try FlowService.shared.create(dto: createDto)
                showModal = false
            } catch {
                alertTitle = "Error"
                alertMessage = "Failed to create flow"
                showAlert = true
            }
        }
    }
}





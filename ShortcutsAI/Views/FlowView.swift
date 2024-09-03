//
//  FlowView.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/30.
//

import AppKit
import Foundation
import RealmSwift
import SwiftUI

struct FlowView: View {
    @ObservedResults(Flow.self) var flows
    @State private var showModal = false
    @State private var modalType = "create"
    @State private var currentFlowId: ObjectId?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题和按钮
            HStack(alignment: .center) {
                Text("AI Flow")
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
                Button(action: {
                    openCreateModal()
                }) {
                    Text("Create AI Flow")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#9C99FA"), Color(hex: "#5958D6")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        )
                        .cornerRadius(10)
                        .shadow(color: Color(hex: "#33333322"), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            ).draggable()

            // 滚动视图
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(flows, id: \.id) { flow in
                        FlowItemView(flow: flow, onTap: {
                            openEditModal(id: flow._id)
                        })
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showModal) {
            ModalView(showModal: $showModal, modalType: $modalType, id: $currentFlowId)
                .background(.ultraThinMaterial)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }

    func openEditModal(id: ObjectId) {
        currentFlowId = id
        modalType = "edit"
        showModal = true
    }

    func openCreateModal() {
        currentFlowId = nil
        modalType = "create"
        showModal = true
    }
}

struct FlowItemView: View {
    let flow: Flow
    let onTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(flow.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(flow.prompt)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor)).opacity(0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
//        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct ModalView: View {
    @Binding var showModal: Bool
    @Binding var modalType: String
    @Binding var id: ObjectId?

    @State private var innerName = ""
    @State private var model = ""
    @State private var prompt = ""
    @State private var fixed = false
    @State private var prefer: String = FlowPrefer.clipboard.rawValue
    @State private var temperature: Float = 0

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var previousName = ""

    init(showModal: Binding<Bool>, modalType: Binding<String>, id: Binding<ObjectId?>) {
        _showModal = showModal
        _modalType = modalType
        _id = id
    }

    var body: some View {
        VStack {
            Text(modalType == "create" ? "Create Flow" : "Edit Flow")
                .font(.system(size: 16).bold())
            Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 2).padding(.horizontal, 0).padding(.vertical, 0)
            Form {
                Text("Name")
                    .font(.system(size: 14).bold())
                    .padding(.top, 6)
                CustomTextField(label: "", text: $innerName, placeholder: "Enter flow name")
                // prompt TextField
                Text("Prompt")
                    .font(.system(size: 14).bold())
                    .padding(.top, 6)

                HStack {
                    AutoresizingCustomTextEditor(
                        text: $prompt,
                        font: .systemFont(ofSize: 12),
                        isEditable: true,
                        maxHeight: 420,
                        lineSpacing: 4,
                        placeholder: """
                        Enter Your Prompt
                        You can use ${data} to refer to the data you want to process (optional)
                        """

                    ) {}.padding(8).background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.12))
                        }
                    )
                }

                // fixed Radio
                Toggle(isOn: $fixed) {
                    Text("fixed at statusbar menu")
                }

                // prefer Select
                Text("Prefer")
                    .font(.system(size: 14).bold())
                    .padding(.top, 6)
                Picker("", selection: $prefer) {
                    ForEach(FlowPrefer.allCases, id: \.rawValue) { prefer in
                        Text(prefer.rawValue).tag(prefer.rawValue)
                    }
                }

                // model TextField
                Text("Model")
                    .font(.system(size: 14).bold())
                    .padding(.top, 10)
                CustomTextField(label: "", text: $model)

                // temperature float number
                HStack {
                    Text("Temperature")
                        .font(.system(size: 14).bold())
                    Text("\(temperature, specifier: "%.1f")")
                        .font(.system(size: 14))

                }.padding(.top, 6)

                Slider(value: Binding(
                    get: {
                        temperature
                    },
                    set: { newValue in
                        temperature = round(newValue * 10) / 10
                    }
                ), in: 0 ... 1)
            }

            HStack(alignment: .center, content: ({
                Spacer(minLength: 0)
                Button("Close") {
                    showModal = false
                }
                .buttonStyle(NormalButtonStyle())

                Button(modalType == "create" ? "Create" : "Save") {
                    if modalType == "create" {
                        // Create action
                    } else {
                        // Save action
                    }
                }
                .buttonStyle(NormalButtonStyle(isPrimary: true))

                if modalType == "edit" {
                    Button("Delete") {
                        // Delete action
                    }
                    .buttonStyle(NormalButtonStyle(isDanger: true))
                }

                Spacer(minLength: 0)

            })).padding([.top, .bottom], 10)
            Spacer(minLength: 0)
        }
        .onAppear {
            initFlow()
        }.alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .frame(width: 480, height: 500).padding()
    }

    func initFlow() {
        if let id {
            let flow = FlowService.shared.findFlowById(id)
            if let flow {
                innerName = flow.name
                model = flow.model
                prompt = flow.prompt
                fixed = flow.fixed
                prefer = flow.prefer
                temperature = flow.temperature
            }
        }
    }

    func valid() -> Bool {
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
}

//
//  ExcuteFlowService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/11.
//

import Foundation

class ExcuteFlowService{
    
    static func excute(name:String,input:String,callback: @escaping (String) -> Void) -> () -> (){
        let openAISv = OpenAIService()
        if let (flow,messages) = assambleMessage(name: name, input: input){
            let completionRequest = OpenAICompletionRequest(model: flow.model ?? "gpt-4o-mini" , messages: messages)
            openAISv.onDataReceived = callback
            openAISv.sendRequest(request: completionRequest)
        }
        return openAISv.stopListening
    }
    
    static func excuteStream(name:String,input:String,callback: @escaping (String) -> Void) -> () -> () {
        let openAISv = OpenAIService()
        
        if let (flow,messages) = assambleMessage(name: name, input: input){
            let completionRequest = OpenAICompletionRequest(model: flow.model ?? "gpt-4o-mini" , messages: messages)
            openAISv.onDataReceived = callback
            openAISv.startListening(request: completionRequest)
        }
        
        return openAISv.stopListening
    }
    
    static func assambleMessage(name:String,input:String) -> (Flow,[OpenAIMessage])? {
        let flow = FlowService.shared.find(name: name)
        if flow == nil {
            LogService.shared.log(level: .error, message: "Flow not found \(name)")
            return  nil
        }
        var prompt = flow?.prompt ?? ""
        if prompt.isEmpty {
            LogService.shared.log(level: .error, message: "Prompt is empty \(name)")
            return nil
        }
        
        var isSingle = false
        if prompt.contains("${data}") {
            isSingle = true
            prompt.replace("${data}", with: input)
        }
        var messages : [OpenAIMessage] = [
            OpenAIMessage(role: isSingle ? OpenAIRole.user : OpenAIRole.system, content: prompt)
        ]
        if !isSingle {
            messages.append(OpenAIMessage(role: OpenAIRole.user, content: input))
        }
        return (flow!,messages)
    }
}

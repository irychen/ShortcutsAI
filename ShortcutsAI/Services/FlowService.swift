//
//  FlowService.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import CoreData

struct CreateFlowDTO {
    let name: String
    let prompt: String
    let fixed: Bool?
    let prefer: FlowPrefer?
    let model: String?
    let temperature: Float?
}

struct UpdateFlowDTO {
    let name: String?
    let prompt: String?
    let fixed: Bool?
    let prefer: FlowPrefer?
    let model: String?
    let temperature: Float?
}


class FlowService{
    static let shared = FlowService()
    private let ctx = PersistenceController.shared.container.viewContext
    private init() { }
    
    func create(dto: CreateFlowDTO) throws{
        let flow = Flow(context: ctx)
        
        // check name exists
        if find(name: dto.name) != nil {
            throw FlowError.nameAlreadyExists
        }
        let temperature = dto.temperature ?? 1.0
        if  !isTemperatureValid(temperature: temperature) {
            throw FlowError.invalidTemperature
        }
        
        flow.name = dto.name
        flow.prompt = dto.prompt
        flow.fixed = dto.fixed ?? false
        flow.prefer = dto.prefer?.rawValue ?? FlowPrefer.clipboard.rawValue
        flow.model = dto.model ?? "gpt-4o-mini"
        flow.temperature = temperature
        flow.order = Int64(findAll().count)
        
        do {
            try ctx.save()
        } catch {
            throw FlowError.failedToSave
        }
    }
    
    func isTemperatureValid(temperature: Float) -> Bool {
        return temperature >= 0.0 && temperature <= 1.0
    }
    
    func find( name: String) -> Flow? {
        if name.isEmpty {
            return nil
        }
        let fetchRequest: NSFetchRequest<Flow> = Flow.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.fetchLimit = 1
        do {
            let flows = try ctx.fetch(fetchRequest)
            return flows.first
        } catch {
            return nil
        }
    }
    
    func update( targetName:String, dto: UpdateFlowDTO) throws {
        guard let flow = find(name: targetName) else {
            throw FlowError.notFound
        }
        
        let temperature = dto.temperature ?? flow.temperature 
        if !isTemperatureValid(temperature: temperature) {
            throw FlowError.invalidTemperature
        }
        
        // update
        flow.name = dto.name ?? flow.name
        flow.prompt = dto.prompt ?? flow.prompt
        flow.fixed = dto.fixed ?? flow.fixed
        flow.prefer = dto.prefer?.rawValue ?? flow.prefer
        flow.model = dto.model ?? flow.model
        flow.temperature = temperature
        
        do {
            try ctx.save()
        } catch {
            throw FlowError.failedToSave
        }
    }
    
    private func initFlows(){
        let flow1 = CreateFlowDTO(
            name: "Translate",
            prompt: "play as an expert translator to translate the following text to chinese or english, make sure the translation is accurate",
            fixed: true,
            prefer: .clipboard,
            model: "gpt-4o-mini-2024-07-18",
            temperature: 0.5
        )
        
        let flow2 = CreateFlowDTO(
            name: "Summarize",
            prompt: "Summarize the following text in several sentences: ${data}",
            fixed: true,
            prefer: .screenshot,
            model: "gpt-4o-mini-2024-07-18",
            temperature: 0.5
        )
        
        let flow3 = CreateFlowDTO(
            name: "What is it?",
            prompt: "Explain what the following text is about, it is good to provide relative context, response in chinese: ${data}",
            fixed: true,
            prefer: .clipboard,
            model: "gpt-4o-mini-2024-07-18",
            temperature: 0.5
        )
        
        // English JavaClass Generator
        let flow4 = CreateFlowDTO(
            name: "JavaClass",
            prompt: "Generate a Java class name based on the following text: ${data}",
            fixed: true,
            prefer: .clipboard,
            model: "gpt-4o-mini-2024-07-18",
            temperature: 0.5
        )
        
        // Fix bug
        let flow5 = CreateFlowDTO(
            name: "FixBug",
            prompt: "Fix the bug in the following code, reponse in chinese: ${data}",
            fixed: true,
            prefer: .clipboard,
            model: "claude-3-5-sonnet-20240620",
            temperature: 0.5
        )
        
        do {
            try create(dto: flow1)
            try create(dto: flow2)
            try create(dto: flow3)
            try create(dto: flow4)
            try create(dto: flow5)
        } catch {
            LogService.shared.log(level: .fatal, message: "Failed to create flows in initFlows")
        }
    }
    
    func delete(name: String) throws {
        guard let flow = find(name: name) else {
            throw FlowError.notFound
        }
        ctx.delete(flow)
        do {
            try ctx.save()
        } catch {
            throw FlowError.failedToSave
        }
    }
    
    func findAll() -> [Flow] {
        let fetchRequest: NSFetchRequest<Flow> = Flow.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Flow.order, ascending: true)]
        do {
            let flows =  try ctx.fetch(fetchRequest)
            if flows.isEmpty {
                initFlows()
                return findAll()
            }
            return flows
        } catch {
            return []
        }
    }
    
    func clearAll() {
        let fr: NSFetchRequest<NSFetchRequestResult> = Flow.fetchRequest()
        let del_req = NSBatchDeleteRequest(fetchRequest: fr)
        do {
            try ctx.execute(del_req)
        } catch {
            LogService.shared.log(level: .fatal, message: "Failed to delete all flows")
        }
    }
}


enum FlowPrefer: String, CaseIterable {
    case clipboard = "clipboard"
    case screenshot = "screenshot"
}

enum FlowError: Error {
    case invalidTemperature
    case invalidPrefer
    case nameAlreadyExists
    case failedToSave
    case notFound
    case batchDeleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidTemperature:
            return "Invalid temperature value. It must be between 0.0 and 1.0."
        case .invalidPrefer:
            return "Invalid prefer value."
        case .nameAlreadyExists:
            return "A flow with this name already exists."
        case .failedToSave:
            return "Failed to save the flow."
        case .notFound:
            return "Flow not found."
        case .batchDeleteFailed:
            return "Failed to delete all flows."
        }
    }
}

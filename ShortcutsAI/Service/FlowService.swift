import Foundation
import RealmSwift

class Flow: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var prompt: String
    @Persisted var model: String
    @Persisted var temperature: Float
    @Persisted var fixed = true
    @Persisted var prefer: String = FlowPrefer.clipboard.rawValue
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var order: Int

    convenience init(dto: FlowDto) {
        self.init()
        name = dto.name
        prompt = dto.prompt
        model = dto.model
        temperature = dto.temperature
        fixed = dto.fixed
        prefer = dto.prefer
        createdAt = Date()
        updatedAt = Date()
        order = dto.order // Initialization of order
    }

    func update(with dto: FlowDto) {
        name = dto.name
        prompt = dto.prompt
        model = dto.model
        temperature = dto.temperature
        fixed = dto.fixed
        prefer = dto.prefer
        updatedAt = Date()
        order = dto.order
    }
}

enum FlowPrefer: String, CaseIterable {
    case clipboard
    case screenshot
}

struct FlowDto: Codable {
    var name: String
    var prompt: String
    var model: String
    var temperature: Float
    var fixed: Bool
    var prefer: String
    var order: Int // New order field
}

import Foundation
import RealmSwift
import SwiftUI

class FlowService {
    static let shared = FlowService()
    private let realm: Realm

    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }

    func initDefault() {
        let flows = realm.objects(Flow.self)
        if flows.isEmpty {
            do {
                try realm.write {
                    realm.add([
                        Flow(dto: FlowDto(
                            name: "Translate",
                            prompt: """
                            # You are an expert in translation, please help me translate the following text.
                            1. keep the original meaning.
                            2. The translation should be accurate and fluent.
                            3. if input text is English, output text should be Chinese.
                            4. if input text is Chinese, output text should be English.
                            5. if input text is other language, output text should be Chinese.
                            """,
                            model: "gpt-4o-mini",
                            temperature: 1.0,
                            fixed: true,
                            prefer: FlowPrefer.clipboard.rawValue,
                            order: 1
                        )),
                        Flow(dto: FlowDto(
                            name: "Java Class Name Generator",
                            prompt: """
                            # You are an expert in Java programming, please help me generate a class name.
                            1. The class name should be a noun.
                            2. The class name should be meaningful and concise.
                            3. The class name should be in CamelCase.
                            4. Only output the class name, no need to output extra information.
                            5. if there are multiple recommended class names, output them splited by comma.
                            """,
                            model: "gpt-4o-mini",
                            temperature: 1.0,
                            fixed: true,
                            prefer: FlowPrefer.screenshot.rawValue,
                            order: 2
                        )),
                        Flow(dto: FlowDto(
                            name: "Explainer",
                            prompt: """
                            # You are an expert in explaining things, please help me explain the following text.
                            1. Explain the text in a simple and easy-to-understand way.
                            2. Use simple words and sentences.
                            3. Use examples or analogies to help explain.
                            4. Do not use jargon or technical terms.
                            5. It is best to provide more context and background information.
                            """,
                            model: "gpt-4o-mini",
                            temperature: 1.0,
                            fixed: true,
                            prefer: FlowPrefer.clipboard.rawValue,
                            order: 3
                        )),
                        Flow(dto: FlowDto(
                            name: "Code Review",
                            prompt: """
                            # You are an expert in code review, please help me review the following code.
                            1. Point out the problems in the code.
                            2. Provide suggestions for improvement.
                            3. Explain the reasons for the suggestions.
                            4. Provide examples or references to support the suggestions.
                            5. Be constructive and polite in the review.
                            """,
                            model: "gpt-4o",
                            temperature: 1.0,
                            fixed: true,
                            prefer: FlowPrefer.clipboard.rawValue,
                            order: 4
                        )),
                        // Prompt Engineer
                        Flow(dto: FlowDto(
                            name: "Prompt Engineer",
                            prompt: """
                            # You are an expert in prompt engineering, please help me design a prompt for the following task.
                            1. The prompt should be clear and specific.
                            2. The prompt should provide enough context for the model to generate the desired output.
                            3. The prompt should be concise and to the point.
                            4. The prompt should be written in natural language.
                            5. The prompt should be free of spelling and grammatical errors.
                            """,
                            model: "gpt-4o",
                            temperature: 1.0,
                            fixed: true,
                            prefer: FlowPrefer.clipboard.rawValue,
                            order: 5
                        )),
                    ])
                }
            } catch {
                fatalError("Failed to init default flows: \(error)")
            }
        }
    }

    // Create
    func createFlow(_ dto: FlowDto) throws -> Flow {
        let flow = Flow(dto: dto)
        do {
            try realm.write {
                if flow.order == 0 {
                    // 如果没有指定顺序，将新流程放在最后
                    flow.order = (realm.objects(Flow.self).max(ofProperty: "order") as Int? ?? 0) + 1
                } else {
                    // 如果指定了顺序，调整其他流程的顺序
                    self.adjustOrderForNewFlow(flow)
                }
                realm.add(flow)
            }
            return flow
        } catch {
            throw error
        }
    }

    // Update
    func updateFlow(_ id: ObjectId, with dto: FlowDto) throws {
        guard let flow = realm.object(ofType: Flow.self, forPrimaryKey: id) else {
            throw NSError(domain: "FlowService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Flow not found"])
        }
        do {
            try realm.write {
                let oldOrder = flow.order
                let newOrder = dto.order

                if oldOrder != newOrder {
                    self.adjustOrderForUpdatedFlow(flow, oldOrder: oldOrder, newOrder: newOrder)
                }

                flow.update(with: dto)
            }
        } catch {
            throw error
        }
    }

    // Delete
    func deleteFlow(_ id: ObjectId) throws {
        guard let flow = realm.object(ofType: Flow.self, forPrimaryKey: id) else {
            throw NSError(domain: "FlowService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Flow not found"])
        }
        do {
            try realm.write {
                let deletedOrder = flow.order
                realm.delete(flow)
                self.adjustOrderAfterDeletion(deletedOrder)
            }
        } catch {
            throw error
        }
    }

    // List
    func listFlows() -> Results<Flow> {
        realm.objects(Flow.self).sorted(byKeyPath: "order", ascending: true)
    }

    // Find by Name
    func findFlowByName(_ name: String) -> Flow? {
        realm.objects(Flow.self).filter("name == %@", name).first
    }
    
    // check if flow name exists
    func exists(name: String) -> Bool {
        realm.objects(Flow.self).filter("name == %@", name).count > 0
    }

    // Find by ID
    func findFlowById(_ id: ObjectId) -> Flow? {
        realm.object(ofType: Flow.self, forPrimaryKey: id)
    }

    // 调整顺序 - 新建流程时
    private func adjustOrderForNewFlow(_ newFlow: Flow) {
        let flows = realm.objects(Flow.self).filter("order >= %@", newFlow.order)
        for flow in flows {
            flow.order += 1
        }
    }

    // 调整顺序 - 更新流程时
    private func adjustOrderForUpdatedFlow(_ updatedFlow: Flow, oldOrder: Int, newOrder: Int) {
        let allFlows = realm.objects(Flow.self).sorted(byKeyPath: "order")

        if oldOrder < newOrder {
            // 向下移动
            for flow in allFlows {
                if flow.order > oldOrder, flow.order <= newOrder, flow._id != updatedFlow._id {
                    flow.order -= 1
                }
            }
        } else if oldOrder > newOrder {
            // 向上移动
            for flow in allFlows {
                if flow.order >= newOrder, flow.order < oldOrder, flow._id != updatedFlow._id {
                    flow.order += 1
                }
            }
        }

        updatedFlow.order = newOrder

        // 确保没有重复的 order
        ensureUniqueOrders()
    }

    // 调整顺序 - 删除流程后
    private func adjustOrderAfterDeletion(_ deletedOrder: Int) {
        let flowsToUpdate = realm.objects(Flow.self).filter("order > %@", deletedOrder)
        for flow in flowsToUpdate {
            flow.order -= 1
        }
    }

    // 确保所有流程的 order 是唯一的
    private func ensureUniqueOrders() {
        let allFlows = realm.objects(Flow.self).sorted(byKeyPath: "order")
        var currentOrder = 1

        for flow in allFlows {
            if flow.order != currentOrder {
                flow.order = currentOrder
            }
            currentOrder += 1
        }
    }

    // 重新排序所有流程
    func reorderAllFlows(_ newOrder: [ObjectId]) throws {
        do {
            try realm.write {
                for (index, id) in newOrder.enumerated() {
                    if let flow = realm.object(ofType: Flow.self, forPrimaryKey: id) {
                        flow.order = index + 1
                    }
                }
            }
        } catch {
            throw error
        }
    }
}

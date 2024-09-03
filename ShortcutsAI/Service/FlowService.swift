import Foundation
import RealmSwift
import SwiftUI

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
        order = dto.order // 初始化 order
    }

    func update(with dto: FlowDto) {
        name = dto.name
        prompt = dto.prompt
        model = dto.model
        temperature = dto.temperature
        fixed = dto.fixed
        prefer = dto.prefer
        updatedAt = Date()
        order = dto.order // 更新 order
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
    var order: Int // 新增 order 字段
}

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
                            prompt: "You are an expert in translation, please help me translate the following text.",
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
                            4. The class name should not be too long.
                            5. The class name should not be too short.
                            6. The class name should not be a keyword in Java.
                            7. The class name should not be a built-in class in Java.
                            8. The class name should not be a library name in Java.
                            9. The class name should not be a common name in Java.
                            10. Only output the class name, no need to output the code.
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
                flow.update(with: dto)
                if oldOrder != flow.order {
                    self.adjustOrderForUpdatedFlow(flow, oldOrder: oldOrder)
                }
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
    private func adjustOrderForUpdatedFlow(_ updatedFlow: Flow, oldOrder: Int) {
        if oldOrder < updatedFlow.order {
            // 向下移动
            let flowsToUpdate = realm.objects(Flow.self).filter("order > %@ AND order <= %@", oldOrder, updatedFlow.order)
            for flow in flowsToUpdate {
                flow.order -= 1
            }
        } else if oldOrder > updatedFlow.order {
            // 向上移动
            let flowsToUpdate = realm.objects(Flow.self).filter("order >= %@ AND order < %@", updatedFlow.order, oldOrder)
            for flow in flowsToUpdate {
                flow.order += 1
            }
        }
    }

    // 调整顺序 - 删除流程后
    private func adjustOrderAfterDeletion(_ deletedOrder: Int) {
        let flowsToUpdate = realm.objects(Flow.self).filter("order > %@", deletedOrder)
        for flow in flowsToUpdate {
            flow.order -= 1
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

//
//  AppConfigService.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation
import CoreData


struct UpdateAppConfigRequest: Codable {
    var indexFlowName: String?
    var shortcutFlowName: String?
    var openAIBaseURL: String?
    var openAIKey: String?
    var model: String?
    var ocrYoudaoAppKey: String?
    var ocrYoudaoAppSecret: String?
    var autoSaveToClipboard: Bool?
    var autoStartOnBoot: Bool?
    
    var input: String?
    var output: String?
}


class AppConfigService {
    static let shared = AppConfigService()
    private let ctx = PersistenceController.shared.container.viewContext
    private init() {}
    
    func get() -> AppConfig? {
        let request: NSFetchRequest<AppConfig> = AppConfig.fetchRequest()
        request.fetchLimit = 1
        do {
            let configs = try ctx.fetch(request)
            if configs.count == 0 {
                initAppConfig()
                return get()
            }
            return configs[0]
        } catch {
            return nil
        }
    }
    
    func initAppConfig(){
        let config = AppConfig(context: ctx)
        config.indexFlowName = "Translate"
        config.shortcutFlowName = "Translate"
        config.openAIBaseURL = "https://api.openai.com"
        config.openAIKey = ""
        config.model = "gpt-4o-mini"
        
        config.ocrYoudaoAppKey = ""
        config.ocrYoudaoAppSecret = ""
        
        config.input = ""
        config.output = ""
        
        config.autoSaveToClipboard = true
        config.autoStartOnBoot  = false
        
        do {
            try ctx.save()
        } catch {
            LogService.shared.log(level: .fatal, message:"initializeLocalConfig fail to save: \(error)")
        }
    }
    
    func update( dto: UpdateAppConfigRequest) {
        guard let config = get() else {
            LogService.shared.log(level: .fatal, message: "updateLocalConfig failed to get config")
            return
        }
        
        config.indexFlowName = dto.indexFlowName ?? config.indexFlowName
        config.shortcutFlowName = dto.shortcutFlowName ?? config.shortcutFlowName
        config.openAIBaseURL = dto.openAIBaseURL ?? config.openAIBaseURL
        config.openAIKey = dto.openAIKey ?? config.openAIKey
        config.model = dto.model ?? config.model
        
        config.ocrYoudaoAppKey = dto.ocrYoudaoAppKey ?? config.ocrYoudaoAppKey
        config.ocrYoudaoAppSecret = dto.ocrYoudaoAppSecret ?? config.ocrYoudaoAppSecret
        
        config.input = dto.input ?? config.input
        config.output = dto.output ?? config.output
        
        config.autoSaveToClipboard = dto.autoSaveToClipboard ?? config.autoSaveToClipboard
        config.autoStartOnBoot = dto.autoStartOnBoot ?? config.autoStartOnBoot
        
        
        do {
            try ctx.save()
        } catch {
            LogService.shared.log(level: .fatal, message: "updateLocalConfig fail to save: \(error)")
        }
    }
    
    func clear(){
        let request: NSFetchRequest<AppConfig> = AppConfig.fetchRequest()
        do {
            let configs = try ctx.fetch(request)
            for config in configs {
                ctx.delete(config)
            }
            try ctx.save()
        } catch {
            LogService.shared.log(level: .fatal, message: "clearLocalConfig fail to save: \(error)")
        }
    }
    
    func openAISetupOK () -> Bool {
        let config = get()
        return config?.openAIKey != nil && !config!.openAIKey!.isEmpty
    }
    
    func YoudaoOCRSetupOK () -> Bool {
        let config = get()
        return config?.ocrYoudaoAppKey != nil && !config!.ocrYoudaoAppKey!.isEmpty && config?.ocrYoudaoAppSecret != nil && !config!.ocrYoudaoAppSecret!.isEmpty
    }
}

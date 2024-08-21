//
//  LoginItemsService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/11.
//

import Foundation
import ServiceManagement


class LoginItemsService {
    static let shared = LoginItemsService()

    private let loginItem: SMAppService

    init() {
        loginItem = SMAppService.mainApp
    }
    
    func isInLoginItems() -> Bool {
        loginItem.status == .enabled
    }
    
    func addToLoginItems() {
        do {
            try loginItem.register()
        } catch {
            LogService.shared.log(level: .error, message: "Failed to add login item: \(error)")
        }
    }
    
    func removeFromLoginItems() {
        do {
            try loginItem.unregister()
        } catch {
           LogService.shared.log(level: .error, message: "Failed to remove login item: \(error)")
        }
    }
}

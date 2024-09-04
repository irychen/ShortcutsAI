//
//  LoginItemsService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/11.
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
           print("Failed to add login item: \(error)")
        }
    }
    
    func removeFromLoginItems() {
        do {
            try loginItem.unregister()
        } catch {
            print("Failed to remove login item: \(error)")
        }
    }
}

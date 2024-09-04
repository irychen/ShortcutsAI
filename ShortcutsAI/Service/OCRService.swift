//
//  OCRService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/10.
//

import Foundation
import Cocoa
import CommonCrypto
import Foundation
import SwiftUI


class OCRService{
    
    var selectedOCRService :String {
        UserDefaults.shared.value(for: \.selectedOCRService)
    }
    var ocrYoudaoAppKey :String {
        UserDefaults.shared.value(for: \.ocrYoudaoAppKey)
    }
    var ocrYoudaoAppSecret :String {
        UserDefaults.shared.value(for: \.ocrYoudaoAppSecret)
    }
    var ocrSpaceAPIKey :String {
        UserDefaults.shared.value(for: \.ocrSpaceAPIKey)
    }
    var ocrSpacePreferredLanguage :String {
        UserDefaults.shared.value(for: \.ocrSpacePreferredLanguage)
    }
    
    static let shared = OCRService()
    
    init() {
  
    }
    
    func recognize(_ image: NSImage) throws -> String{
        let youdaoSvc = OCRYoudaoService(appKey: ocrYoudaoAppKey, appSecret: ocrYoudaoAppSecret)
        let spaceSvc = OCRSpaceService(apikey: ocrSpaceAPIKey, language: ocrSpacePreferredLanguage)
        
        if selectedOCRService == "youdao" {
            return try youdaoSvc.takeOCRSync(image)
        } else {
            return try spaceSvc.takeOCRSync(image)
        }
    }
}

//
//  ImageUtil.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/11.
//

import Foundation
import SwiftUI
import Cocoa

class ImageUtil{
   static func imageToBase64(image: NSImage) -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            LogService.shared.log(level: .fatal, message: "Failed to get CGImage from NSImage")
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            LogService.shared.log(level: .fatal, message: "Failed to create PNG data")
            return nil
        }
        
        return pngData.base64EncodedString()
    }
}

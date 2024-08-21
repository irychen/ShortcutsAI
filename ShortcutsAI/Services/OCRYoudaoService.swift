//
//  OCRYoudaoService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/11.
//

import Foundation
import CommonCrypto
import SwiftUI
import Cocoa

class OCRYoudaoService{
    
    private var youDaoURL = "https://openapi.youdao.com/ocrapi"
    private var appKey = ""
    private var appSecret = ""
    
    init (appKey: String, appSecret: String) {
        self.appKey = appKey
        self.appSecret = appSecret
    }
    
    func takeOCRSync(image: NSImage) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        takeOCR(image: image) { res in
            switch res {
            case .success(let text):
                result = text
            case .failure(let error):
                LogService.shared.log(level: .error, message: "Failed to take Youdao OCR: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    func takeOCR(image: NSImage, completion: @escaping (Result<String, Error>) -> Void) {
        let imageBase64Str = ImageUtil.imageToBase64(image: image) ?? ""
        // Generate necessary parameters
        let salt = UUID().uuidString
        let curtime = String(Int(Date().timeIntervalSince1970))
        let input = imageBase64Str.count >= 20
        ? imageBase64Str.prefix(10) + String(imageBase64Str.count) + imageBase64Str.suffix(10)
        : imageBase64Str
        let signStr = appKey + input + salt + curtime + appSecret
        let sign = sha256(signStr)
        
        // Create request parameters
        let params: [String: Any] = [
            "img": imageBase64Str,
            "langType": "auto",
            "detectType": "10012",
            "imageType": "1",
            "appKey": appKey,
            "salt": salt,
            "sign": sign,
            "docType": "json",
            "signType": "v3",
            "curtime": curtime
        ]
        
        // Create URL request
        var request = URLRequest(url: URL(string: youDaoURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params.percentEncoded()
        
        // Perform the request
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    //                    print(json)
                    let text = self.parseOCRResult(json: json)
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    // Helper function to parse bounding box
    private func parseBoundingBox(_ boundingBox: String) -> (lt: CGPoint, rb: CGPoint) {
        let coords = boundingBox.split(separator: ",").compactMap { Double($0) }
        if coords.count == 8 {
            return (CGPoint(x: coords[0], y: coords[1]), CGPoint(x: coords[4], y: coords[5]))
        }
        return (CGPoint.zero, CGPoint.zero)
    }
    
    // Helper function to format text based on bounding boxes
    private func formatText(_ lastBounding: (lt: CGPoint, rb: CGPoint)?, _ bounding: (lt: CGPoint, rb: CGPoint), _ textResult: String) -> String {
        var textResult = textResult
        if let last = lastBounding {
            let verticalGap = bounding.lt.y - last.rb.y
            let horizontalGap = bounding.lt.x - last.rb.x
            if verticalGap > 10 {
                textResult += "\n"
            } else if horizontalGap > 10 {
                textResult += " "
            } else {
                textResult += " " // Ensure there is always a space between words
            }
        } else {
            textResult += " " // Ensure there is always a space for the first word
        }
        return textResult
    }
    
    // Helper function to parse OCR result
    private func parseOCRResult(json: [String: Any]) -> String {
        guard let result = json["Result"] as? [String: Any],
              let regions = result["regions"] as? [[String: Any]] else {
            return ""
        }
        
        var textResult = ""
        var min_x: Double = 0
        var lastBounding: (lt: CGPoint, rb: CGPoint)? = nil
        
        for region in regions {
            if let lines = region["lines"] as? [[String: Any]], let boundingBox = region["boundingBox"] as? String {
                let bounding = parseBoundingBox(boundingBox)
                min_x = min_x == 0 ? bounding.lt.x : min(min_x, bounding.lt.x)
                textResult = formatText(lastBounding, bounding, textResult)
                lastBounding = bounding
                
                for line in lines {
                    if let text = line["text"] as? String, let boundingBox = line["boundingBox"] as? String {
                        let bounding = parseBoundingBox(boundingBox)
                        min_x = min_x == 0 ? bounding.lt.x : min(min_x, bounding.lt.x)
                        textResult = formatText(lastBounding, bounding, textResult)
                        lastBounding = bounding
                        textResult += text
                    }
                }
            }
        }
        
        // Replace pendingSpaceGap with actual spaces
        let pattern = "_{pendingSpaceGap-(\\d+)}_"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        if let regex = regex {
            let matches = regex.matches(in: textResult, options: [], range: NSRange(location: 0, length: textResult.utf16.count))
            for match in matches.reversed() {
                let matchRange = match.range(at: 1)
                let pendingSpaceGapStr = (textResult as NSString).substring(with: matchRange)
                if let pendingSpaceGap = Double(pendingSpaceGapStr) {
                    let realSpaceCount = Int(abs(pendingSpaceGap - min_x) / 15)
                    let spaces = String(repeating: " ", count: realSpaceCount)
                    textResult = (textResult as NSString).replacingCharacters(in: match.range, with: spaces)
                }
            }
        }
        
        return textResult.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Helper function to generate SHA256 hash
    private func sha256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// URL encoding for parameters
extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}



/*
 
 AAA BBB CCC
 
 DDD EEE FFF
 
 CCC
 BBB
 HHH
 
 
 
 */

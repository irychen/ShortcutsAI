//
//  OCRSpaceService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/2.
//

import Cocoa
import CommonCrypto
import Foundation
import SwiftUI

public let languageOptions = [
    SelectOption(value: "ara", label: "Arabic"),
    SelectOption(value: "bul", label: "Bulgarian"),
    SelectOption(value: "chs", label: "Chinese (Simplified)"),
    SelectOption(value: "cht", label: "Chinese (Traditional)"),
    SelectOption(value: "hrv", label: "Croatian"),
    SelectOption(value: "cze", label: "Czech"),
    SelectOption(value: "dan", label: "Danish"),
    SelectOption(value: "dut", label: "Dutch"),
    SelectOption(value: "eng", label: "English"),
    SelectOption(value: "fin", label: "Finnish"),
    SelectOption(value: "fre", label: "French"),
    SelectOption(value: "ger", label: "German"),
    SelectOption(value: "gre", label: "Greek"),
    SelectOption(value: "hun", label: "Hungarian"),
    SelectOption(value: "kor", label: "Korean"),
    SelectOption(value: "ita", label: "Italian"),
    SelectOption(value: "jpn", label: "Japanese"),
    SelectOption(value: "pol", label: "Polish"),
    SelectOption(value: "por", label: "Portuguese"),
    SelectOption(value: "rus", label: "Russian"),
    SelectOption(value: "slv", label: "Slovenian"),
    SelectOption(value: "spa", label: "Spanish"),
    SelectOption(value: "swe", label: "Swedish"),
    SelectOption(value: "tur", label: "Turkish"),
]

enum OCRSpaceError: Error {
    case notFoundAPIKey
    case requestFailed(String)
    var description: String {
        switch self {
        case .notFoundAPIKey:
            return "Not found API Key"
        case let .requestFailed(message):
            return "Request failed: \(message)"
        }
    }
}

class OCRSpaceService {
    let OCRSpaceURL = "https://api.ocr.space/parse/image"
    var apikey: String
    var language: String?
    var isTable = false

    init(apikey: String, language: String? = nil) {
        self.apikey = apikey
        self.language = language
    }

    func takeOCRSync(_ image: NSImage) throws -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        var errorOccurred: Error?

        takeOCR(image) { res in
            switch res {
            case let .success(text):
                result = text
            case let .failure(error):
                errorOccurred = error
            }
            semaphore.signal()
        }
        semaphore.wait()

        if let error = errorOccurred {
            throw error
        }

        return result
    }

    func takeOCR(_ image: NSImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageBase64Str = ImageUtil.imageToBase64(image: image) else {
            completion(.failure(OCRSpaceError.requestFailed("Failed to convert image to Base64 string")))
            return
        }
        // check API key
        if apikey.isEmpty {
            completion(.failure(OCRSpaceError.notFoundAPIKey))
            return
        }

        let dataStr = "data:image/png;base64," + imageBase64Str

        let params: [String: Any] = [
            "base64Image": dataStr,
            "apikey": apikey,
            "language": language ?? "eng",
            "isTable": isTable,
            "detectOrientation": true,
            "OCREngine": "2",
        ]

        guard let url = URL(string: OCRSpaceURL) else {
            completion(.failure(OCRYoudaoError.requestFailed("Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params.percentEncoded()
        request.timeoutInterval = 20.0 // Set timeout interval to 10 seconds
        // Perform the request
        let session = URLSession.shared
        session.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(OCRYoudaoError.requestFailed(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(OCRYoudaoError.noData))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let text = self.parseOCRResult(json: json)
                    completion(.success(text))
                } else {
                    completion(.failure(OCRYoudaoError.invalidResponse("Invalid JSON structure")))
                }
            } catch {
                completion(.failure(OCRYoudaoError.jsonParsingError(error.localizedDescription)))
            }
        }.resume()
    }

    private func parseOCRResult(json: [String: Any]) -> String {
        // print("json: \(json)")
        
        // Check for the "ParsedResults" key in the JSON dictionary
        guard let parsedResults = json["ParsedResults"] as? [[String: Any]] else {
            return ""
        }

        // The "ParsedResults" array should contain at least one element
        guard let firstResult = parsedResults.first else {
            return ""
        }

        // Check for the "ParsedText" key in the first element of the "ParsedResults" array
        guard let parsedText = firstResult["ParsedText"] as? String else {
            return ""
        }

        //print("parsedText: \(parsedText)")

        // Return the parsed text
        return parsedText
    }
}

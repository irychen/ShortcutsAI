//
//  OpenAIService.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/8/11.
//

import Foundation

struct OpenAICompletionRequest: Codable {
    var model: String = "gpt-40-mini"
    var messages: [OpenAIMessage]
}

struct OpenAIMessage: Codable {
    var role: OpenAIRole
    var content: String
}

enum OpenAIRole: String, Codable {
    case user
    case assistant
    case system
}


class OpenAIService: NSObject {
    private var urlSession: URLSession!
    private var task: URLSessionDataTask?
    var onDataReceived: ((String) -> Void)?
    
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    
    func startListening(request: OpenAICompletionRequest) {
        let appConfig = AppConfigService.shared.get()
        let apiKey = appConfig?.openAIKey ?? ""
        if apiKey.isEmpty {
            LogService.shared.log(level: .error, message: "API Key is empty")
            return
        }
        let base_url = appConfig?.openAIBaseURL ?? "https://api.openai.com"
        let whole_url = base_url + "/v1/chat/completions"
        guard let url = URL(string: whole_url) else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var body = try? JSONEncoder().encode(request)
        if var jsonObject = try? JSONSerialization.jsonObject(with: body!, options: []) as? [String: Any] {
            jsonObject["stream"] = true
            body = try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
        }
        
        urlRequest.httpBody = body
        
        task = urlSession.dataTask(with: urlRequest)
        task?.resume()
    }
    
    func sendRequest(request: OpenAICompletionRequest) {
        let appConfig = AppConfigService.shared.get()
        let apiKey = appConfig?.openAIKey ?? ""
        if apiKey.isEmpty {
            LogService.shared.log(level: .error, message: "API Key is empty")
            return
        }
        let base_url = appConfig?.openAIBaseURL ?? "https://api.openai.com"
        let whole_url = base_url + "/v1/chat/completions"
        guard let url = URL(string: whole_url) else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body = try? JSONEncoder().encode(request)
        urlRequest.httpBody = body
        
        task = urlSession.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                LogService.shared.log(level: .error, message: "Failed to send request to OpenAI: \(error)")
                return
            }
            
            guard let data = data else {
                LogService.shared.log(level: .error, message: "No data received from OpenAI")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    self.onDataReceived?(content)
                }
            } catch {
                LogService.shared.log(level: .error, message: "Failed to parse response from OpenAI: \(error)")
            }
        }
        
        task?.resume()
    }
    
    func stopListening() {
        task?.cancel()
    }
}

extension OpenAIService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let eventString = String(data: data, encoding: .utf8) {
            onDataReceived?(eventString)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            LogService.shared.log(level: .error, message: "Task completed with error: \(error.localizedDescription)")
        } else {
            LogService.shared.log(level: .info, message: "Task completed successfully without error ")
        }
    }
    
    static func handleStreamedData( dataString: String)->String {
        var text = ""
        let lines = dataString.split(separator: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    return text
                } else {
                    if let jsonData = jsonString.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let choices = jsonObject["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String {
                        text += content
                    }
                }
            }
        }
        return text
    }
    
    static func isResDone(dataString: String)->Bool {
        let lines = dataString.split(separator: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    return true
                }
            }
        }
        return false
    }
}

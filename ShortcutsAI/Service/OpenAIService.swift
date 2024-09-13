import AppKit
import Foundation
import RealmSwift
import SwiftUI

struct OpenAICompletionRequest: Codable {
    var model: String = "gpt-40-mini"
    var messages: [OpenAIMessage]
    var temperature: Float = 1.0
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

enum OpenAIServiceError: Error {
    case notFoundAPIKey
    case requestFailed(String)
    case noDataReceived
    case jsonParsingFailed(String)

    var description: String {
        switch self {
        case .notFoundAPIKey:
            return "API Key not found"
        case let .requestFailed(message):
            return "Request failed: \(message)"
        case .noDataReceived:
            return "No data received from the server"
        case let .jsonParsingFailed(message):
            return "Failed to parse JSON: \(message)"
        }
    }
}

struct OpenAIStreamResponse {
    var text: String
    var isDone: Bool
}

class OpenAIService: NSObject {
    private var urlSession: URLSession!
    private var task: URLSessionDataTask?
    var onDataReceived: ((OpenAIStreamResponse) -> Void)?

    static var specialModels = ["o1-mini", "o1-preview", "o1-mini-2024-09-12", "o1-preview-2024-09-12"]

    public static func isSpecialModel(_ model: String) -> Bool {
        return specialModels.contains(model)
    }

    public static var openAImodels = [
        "gpt-4o-mini-2024-07-18",
        "gpt-4o-mini",
        "gpt-4o-2024-08-06",
        "gpt-4o",
        "gpt-3.5-turbo",
        "claude-3-5-sonnet-20240620",
        "o1-preview",
        "o1-mini"
    ]

    var openAIKey: String {
        UserDefaults.shared.value(for: \.openAIKey)
    }

    var openAIBaseURL: String {
        UserDefaults.shared.value(for: \.openAIBaseURL)
    }

    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    func send(request: OpenAICompletionRequest, stream: Bool = true) throws {
        var specialModel = OpenAIService.isSpecialModel(request.model)

        if openAIKey.isEmpty {
            throw OpenAIServiceError.notFoundAPIKey
        }

        var base_url = openAIBaseURL.isEmpty ? "https://api.openai.com" : openAIBaseURL
        if !base_url.hasSuffix("/") {
            base_url += "/"
        }
        let whole_url = base_url + "v1/chat/completions"
        guard let url = URL(string: whole_url) else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")

        var reqData = OpenAICompletionRequest(
            model: request.model,
            messages: request.messages,
            temperature: request.temperature)

        if specialModel {
            reqData.temperature = 1
        }

        var body = try? JSONEncoder().encode(reqData)

        if !specialModel && stream {
            if var jsonObject = try? JSONSerialization.jsonObject(with: body!, options: [])
                as? [String: Any]
            {
                jsonObject["stream"] = true
                body = try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
            }

            urlRequest.httpBody = body

            task = urlSession.dataTask(with: urlRequest)

        } else {
            urlRequest.timeoutInterval = 120.0
            urlRequest.httpBody = body
            task = urlSession.dataTask(with: urlRequest) { data, _, error in
                if let error = error {
                    self.onDataReceived?(
                        OpenAIStreamResponse(text: "Error: \(error.localizedDescription)", isDone: true))
                    return
                }

                guard let data = data else {
                    self.onDataReceived?(OpenAIStreamResponse(text: "Error: No data received", isDone: true))
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String
                    {
                        self.onDataReceived?(OpenAIStreamResponse(text: content, isDone: true))
                    } else {
                        self.onDataReceived?(
                            OpenAIStreamResponse(text: "Error: Invalid JSON structure \(json)", isDone: true))
                    }
                } catch {
                    self.onDataReceived?(
                        OpenAIStreamResponse(text: "Error: \(error.localizedDescription)", isDone: true))
                }
            }
        }
        task?.resume()
    }

    func stopListening() {
        task?.cancel()
    }

    func executeFlow(name: String, input: String, callback: @escaping (OpenAIStreamResponse) -> Void)
        throws
        -> () -> Void
    {
        let data = assembleFlowData(flowName: name, input: input)
        do {
            try send(request: data)
            onDataReceived = callback
        } catch {
            throw error
        }
        return stopListening
    }

    func assembleFlowData(flowName: String, input: String) -> OpenAICompletionRequest {
        var data = OpenAICompletionRequest(
            model: "gpt-40-mini",
            messages: [],
            temperature: 1.0)
        let realm = try! Realm()
        if let flow = realm.objects(Flow.self).filter("name = %@", flowName).first {
            data.model = flow.model
            data.temperature = flow.temperature
            var prompt = flow.prompt
            var isSingle = false
            if prompt.contains("${data}") {
                isSingle = true
                prompt.replace("${data}", with: input)
            }
            var messages: [OpenAIMessage] = [
                OpenAIMessage(role: isSingle ? OpenAIRole.user : OpenAIService.isSpecialModel(flow.model) ? OpenAIRole.user : OpenAIRole.system, content: prompt)
            ]
            if !isSingle {
                messages.append(OpenAIMessage(role: OpenAIRole.user, content: input))
            }
            data.messages = messages
        } else {
            data.messages = [
                OpenAIMessage(role: OpenAIRole.user, content: input)
            ]
        }
        return data
    }
}

extension OpenAIService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let eventString = String(data: data, encoding: .utf8) {
            let text = OpenAIService.handleStreamedData(dataString: eventString)
            print(text)
            let isDone = OpenAIService.isResDone(dataString: eventString)
            onDataReceived?(OpenAIStreamResponse(text: text, isDone: isDone))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
    }

    static func handleStreamedData(dataString: String) -> String {
        var text = ""
        let lines = dataString.split(separator: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                var jsonString = String(line.dropFirst(6))
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                if jsonString == "[DONE]" {
                    return text
                } else {
                    if let jsonData = jsonString.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: [])
                       as? [String: Any],
                       let choices = jsonObject["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String
                    {
                        text += content
                    }
                }
            }
        }
        return text
    }

    static func isResDone(dataString: String) -> Bool {
        let lines = dataString.split(separator: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                var jsonString = String(line.dropFirst(6))
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                if jsonString == "[DONE]" {
                    return true
                }
                if let jsonData = jsonString.data(using: .utf8) {
                    if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: [])
                        as? [String: Any]
                    {
                        let choices = jsonObject["choices"] as? [[String: Any]]
                        if let data = choices?.first {
                            if data["finish_reason"] as? String == "stop" {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }
}

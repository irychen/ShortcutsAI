
import Foundation

public protocol UserDefaultPreferenceKey {
    associatedtype Value
    var defaultValue: Value { get }
    var key: String { get }
}

public struct PreferenceKey<T>: UserDefaultPreferenceKey {
    public let defaultValue: T
    public let key: String

    public init(defaultValue: T, key: String) {
        self.defaultValue = defaultValue
        self.key = key
    }
}

public struct UserDefaultPreferenceKeys {
    public init() {}
    // ------------ section of OpenAI Service ------------
    var openAIKey = PreferenceKey<String>(defaultValue: "", key: "OpenAIKey")
    var openAIBaseURL = PreferenceKey<String>(defaultValue: "https://api.openai.com", key: "OpenAIBaseURL")
    var defaultFlowModel = PreferenceKey<String>(defaultValue: "gpt-4o-mini", key: "DefaultFlowModel")
    var openAImodels = PreferenceKey<[String]>(defaultValue: [
        "gpt-4o-mini-2024-07-18",
        "gpt-4o-mini",
        "gpt-4o-2024-08-06",
        "gpt-4o",
        "gpt-3.5-turbo",
        "claude-3-5-sonnet-20240620",
    ], key: "OpenAIModels")

    // ------------ section of OCR Service ------------
    var selectedOCRService = PreferenceKey<String>(defaultValue: "ocrspace", key: "SelectedOCRService")
    var ocrYoudaoAppKey = PreferenceKey<String>(defaultValue: "", key: "OCRYoudaoAppKey")
    var ocrYoudaoAppSecret = PreferenceKey<String>(defaultValue: "", key: "OCRYoudaoAppSecret")
    var ocrSpaceAPIKey = PreferenceKey<String>(defaultValue: "", key: "OCRSpaceAPIKey")
    var ocrSpacePreferredLanguage = PreferenceKey<String>(defaultValue: "eng", key: "OCRSpacePreferredLanguage")

    // ------------ section of Other ------------
    var shortcutsFlowName = PreferenceKey<String>(defaultValue: "Translate", key: "ShortcutsFlowName")
    var autoSaveToClipboard = PreferenceKey<Bool>(defaultValue: true, key: "AutoSaveToClipboard")
    var autoStartOnBoot = PreferenceKey<Bool>(defaultValue: false, key: "AutoStartOnBoot")
    var autoOpenResultPanel = PreferenceKey<Bool>(defaultValue: true, key: "AutoOpenResultPanel")

    var appIsInitialized = PreferenceKey<Bool>(defaultValue: false, key: "AppIsInitizalized")
}

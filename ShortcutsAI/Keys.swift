
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

    // ------------ section of Translator ------------
    var translateFrom = PreferenceKey<String>(defaultValue: "auto", key: "TranslateFrom")
    var translateTo = PreferenceKey<String>(defaultValue: "Chinese", key: "TranslateTo")
    var translateInputText = PreferenceKey<String>(defaultValue: "", key: "TranslateInputText")
    var translateOutputText = PreferenceKey<String>(defaultValue: "", key: "TranslateOutputText")
    var translateModel = PreferenceKey<String>(defaultValue: "gpt-4o-mini", key: "TranslateModel")
    var translateTemperature = PreferenceKey<Double>(defaultValue: 0.5, key: "TranslateTemperature")

    // ------------ Other ------------
    var inputText = PreferenceKey<String>(defaultValue: "", key: "InputText")
    var outputText = PreferenceKey<String>(defaultValue: "", key: "OutputText")
    var homeSelectedFlowName = PreferenceKey<String>(defaultValue: "Translate", key: "HomeSelectedFlowName")
    var maxHistoryRecordCount = PreferenceKey<Int>(defaultValue: 100, key: "MaxHistoryRecordCount")
    
    var currentAppTabKey = PreferenceKey<String>(defaultValue: "home", key: "CurrentAppTabKey")
    var globalRunLoading = PreferenceKey<Bool>(defaultValue: false, key: "GlobalRunLoading")
    
}

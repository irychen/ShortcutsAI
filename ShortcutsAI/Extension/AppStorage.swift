//
//  AppStorage.swift
//  ShortcutsAI
//
//  Created by Yichen Wong on 2024/9/2.
//

import Foundation
import SwiftUI

public protocol UserDefaultsType {
    func value(forKey: String) -> Any?
    func set(_ value: Any?, forKey: String)
}

public extension UserDefaults {
    static var shared = UserDefaults(suiteName: userDefaultSuiteName)!

    static func setupDefaultSettings() {
        shared.setupDefaultValue(for: \.shortcutsFlowName)
        shared.setupDefaultValue(for: \.selectedOCRService)
        shared.setupDefaultValue(for: \.ocrYoudaoAppKey)
        shared.setupDefaultValue(for: \.ocrYoudaoAppSecret)
        shared.setupDefaultValue(for: \.ocrSpaceAPIKey)
        shared.setupDefaultValue(for: \.openAIKey)
        shared.setupDefaultValue(for: \.openAIBaseURL)
        shared.setupDefaultValue(for: \.defaultFlowModel)
        shared.setupDefaultValue(for: \.openAImodels)
        shared.setupDefaultValue(for: \.ocrSpacePreferredLanguage)
        shared.setupDefaultValue(for: \.appIsInitialized)
        
        shared.setupDefaultValue(for: \.currentAppTabKey)
        shared.setupDefaultValue(for: \.translateTemperature)
    }
}

extension UserDefaults: UserDefaultsType {}

public protocol UserDefaultsStorable {}

extension Int: UserDefaultsStorable {}
extension Double: UserDefaultsStorable {}
extension Bool: UserDefaultsStorable {}
extension String: UserDefaultsStorable {}
extension Data: UserDefaultsStorable {}
extension URL: UserDefaultsStorable {}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

public struct UserDefaultsStorageBox<Element: Codable>: RawRepresentable {
    public let value: Element

    public init(_ value: Element) {
        self.value = value
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Element.self, from: data)
        else {
            return nil
        }
        value = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(value),
              let result = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return result
    }
}

extension UserDefaultsStorageBox: Equatable where Element: Equatable {}

public extension UserDefaultsType {
    // MARK: Normal Types

    func value<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> K.Value where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        return (value(forKey: key.key) as? K.Value) ?? key.defaultValue
    }

    func set<K: UserDefaultPreferenceKey>(
        _ value: K.Value,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(value, forKey: key.key)
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(key.defaultValue, forKey: key.key)
        }
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>,
        defaultValue: K.Value
    ) where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(defaultValue, forKey: key.key)
        }
    }

    // MARK: Raw Representable

    func value<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> K.Value where K.Value: RawRepresentable, K.Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? String else {
            return key.defaultValue
        }
        return K.Value(rawValue: rawValue) ?? key.defaultValue
    }

    func value<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> K.Value where K.Value: RawRepresentable, K.Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? Int else {
            return key.defaultValue
        }
        return K.Value(rawValue: rawValue) ?? key.defaultValue
    }

    func value<K: UserDefaultPreferenceKey, V>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> V where K.Value == UserDefaultsStorageBox<V> {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? String else {
            return key.defaultValue.value
        }
        return (K.Value(rawValue: rawValue) ?? key.defaultValue).value
    }

    func set<K: UserDefaultPreferenceKey>(
        _ value: K.Value,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: RawRepresentable, K.Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(value.rawValue, forKey: key.key)
    }

    func set<K: UserDefaultPreferenceKey>(
        _ value: K.Value,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: RawRepresentable, K.Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(value.rawValue, forKey: key.key)
    }

    func set<K: UserDefaultPreferenceKey, V: Codable>(
        _ value: V,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == UserDefaultsStorageBox<V> {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(UserDefaultsStorageBox(value).rawValue, forKey: key.key)
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>,
        defaultValue: K.Value? = nil
    ) where K.Value: RawRepresentable, K.Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(defaultValue?.rawValue ?? key.defaultValue.rawValue, forKey: key.key)
        }
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>,
        defaultValue: K.Value? = nil
    ) where K.Value: RawRepresentable, K.Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(defaultValue?.rawValue ?? key.defaultValue.rawValue, forKey: key.key)
        }
    }
}

public extension AppStorage {
    // Bool
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Bool {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // String
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // Double
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Double {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // Int
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // URL
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == URL {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // Data
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Data {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // RawRepresentable Int
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value: RawRepresentable, Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }

    // RawRepresentable String
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value: RawRepresentable, Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(wrappedValue: key.defaultValue, key.key, store: .shared)
    }
}

public extension AppStorage where Value: ExpressibleByNilLiteral {
    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Bool? {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }

    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == String? {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }

    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Double? {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }

    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Int? {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }

    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == URL? {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }

    init<K: UserDefaultPreferenceKey>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == Data? {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }
}

public extension AppStorage {
    init<K: UserDefaultPreferenceKey, R>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == R?, R: RawRepresentable, R.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }

    init<K: UserDefaultPreferenceKey, R>(
        _ keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value == Value, Value == R?, R: RawRepresentable, R.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        self.init(key.key, store: .shared)
    }
}

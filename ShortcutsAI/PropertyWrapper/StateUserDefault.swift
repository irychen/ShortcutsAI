//
//  StateUserDefault.swift
//  ShortcutsAI
//
//  Created by fine on 2024/8/30.
//

import Foundation
import SwiftUI

@propertyWrapper
struct StateUserDefault<T>: DynamicProperty {
    @State private var value: T
    private let key: String

    init(_ key: String, defaultValue: T) {
        self.key = key
        let initialValue = UserDefaults.standard.object(forKey: key).flatMap { storedValue in
            (storedValue as? T) ?? (T.self == Int.self ? (storedValue as? NSNumber)?.intValue as? T : nil)
        } ?? defaultValue
        _value = State(initialValue: initialValue)
    }

    var wrappedValue: T {
        get { value }
        nonmutating set {
            value = newValue
            saveValue(newValue)
        }
    }

    var projectedValue: Binding<T> {
        Binding(
            get: { value },
            set: { newValue in
                value = newValue
                saveValue(newValue)
            }
        )
    }

    private func saveValue(_ newValue: T) {
        DispatchQueue.global().async {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

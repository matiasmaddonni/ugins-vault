//
//  UserDefaultsSessionStorage.swift
//  UginsVault — Data layer
//
//  Persists session prefs to `UserDefaults`. Migrating to a Keychain-backed
//  store is straightforward — replace this implementation and reuse the
//  `SessionStorageDataSource`.
//

import Foundation

public final class UserDefaultsSessionStorage: SessionStorageDataSource, @unchecked Sendable {

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

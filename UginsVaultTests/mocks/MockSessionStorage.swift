//
//  MockSessionStorage.swift
//  UginsVaultTests
//

import Foundation
@testable import UginsVault

final class MockSessionStorage: SessionStorageDataSourceProtocol, @unchecked Sendable {

    private var store: [String: String] = [:]

    func string(forKey key: String) -> String? {
        store[key]
    }

    func set(_ value: String?, forKey key: String) {
        if let value {
            store[key] = value
        } else {
            store.removeValue(forKey: key)
        }
    }
}

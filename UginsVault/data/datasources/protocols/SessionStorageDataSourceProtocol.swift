//
//  SessionStorageDataSourceProtocol.swift
//  UginsVault — Data layer
//
//  Tiny key/value contract for session prefs. The live impl is
//  `UserDefaultsSessionStorage`; tests use an in-memory mock.
//

import Foundation

public protocol SessionStorageDataSourceProtocol: Sendable {

    func string(forKey key: String) -> String?
    func set(_ value: String?, forKey key: String)
}

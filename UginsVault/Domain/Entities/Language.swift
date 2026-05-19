//
//  Language.swift
//  UginsVault — Domain layer
//
//  User-controlled language preference. `.system` follows the device.
//  English + Spanish are the supported pinned locales; anything else
//  falls back to English via the String Catalog's development language.
//

import Foundation

public enum Language: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case english
    case spanish

    public var id: String { rawValue }

    /// The locale to apply via `.environment(\.locale, …)`. Returns `nil`
    /// for `.system` so SwiftUI keeps following the device.
    public var locale: Locale? {
        switch self {
        case .system:  return nil
        case .english: return Locale(identifier: "en")
        case .spanish: return Locale(identifier: "es")
        }
    }
}

//
//  UserDefaultsSessionRepository.swift
//  UginsVault — Data layer
//
//  Stores the user's lightweight session state (phase, theme, currency) via a
//  `SessionStorageDataSource`. SwiftData is reserved for the collection
//  catalogue itself.
//

import Foundation
import Observation

@Observable
public final class UserDefaultsSessionRepository: SessionRepository {

    // MARK: - Keys

    private enum Key {
        static let phase    = "uv.session.phase"
        static let theme    = "uv.session.theme"
        static let currency = "uv.session.currency"
    }

    // MARK: - Dependencies

    @ObservationIgnored private let storage: SessionStorageDataSource

    public init(storage: SessionStorageDataSource) {
        self.storage = storage
    }

    // MARK: - Phase

    public func loadPhase() -> AppPhase {
        guard let raw = storage.string(forKey: Key.phase),
              let phase = AppPhase(rawValue: raw) else { return .splash }
        return phase
    }

    public func savePhase(_ phase: AppPhase) {
        storage.set(phase.rawValue, forKey: Key.phase)
    }

    // MARK: - Theme

    public func loadTheme() -> AppTheme {
        guard let raw = storage.string(forKey: Key.theme),
              let theme = AppTheme(rawValue: raw) else { return .dark }
        return theme
    }

    public func saveTheme(_ theme: AppTheme) {
        storage.set(theme.rawValue, forKey: Key.theme)
    }

    // MARK: - Currency

    public func loadCurrency() -> Currency {
        guard let raw = storage.string(forKey: Key.currency),
              let currency = Currency(rawValue: raw) else { return .usd }
        return currency
    }

    public func saveCurrency(_ currency: Currency) {
        storage.set(currency.rawValue, forKey: Key.currency)
    }
}

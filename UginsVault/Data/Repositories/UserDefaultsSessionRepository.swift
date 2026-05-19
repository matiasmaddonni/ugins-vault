//
//  UserDefaultsSessionRepository.swift
//  UginsVault — Data layer
//
//  Stores the user's lightweight session state (phase, theme, currency,
//  language, reduce-motion, Face ID lock) via a `SessionStorageDataSource`.
//  SwiftData is reserved for the collection catalogue itself.
//

import Foundation
import Observation

@Observable
public final class UserDefaultsSessionRepository: SessionRepository {

    // MARK: - Keys

    private enum Key {
        static let phase        = "uv.session.phase"
        static let theme        = "uv.session.theme"
        static let currency     = "uv.session.currency"
        static let language     = "uv.session.language"
        static let reduceMotion = "uv.session.reduceMotion"
        static let faceIDLock   = "uv.session.faceIDLock"
    }

    // MARK: - Observable state

    public private(set) var phase:        AppPhase
    public private(set) var theme:        AppTheme
    public private(set) var currency:     Currency
    public private(set) var language:     Language
    public private(set) var reduceMotion: Bool
    public private(set) var faceIDLock:   Bool

    // MARK: - Dependencies

    @ObservationIgnored private let storage: SessionStorageDataSource

    // MARK: - Init

    public init(storage: SessionStorageDataSource) {
        self.storage = storage

        self.phase = AppPhase(rawValue: storage.string(forKey: Key.phase) ?? "")
            ?? .splash
        self.theme = AppTheme(rawValue: storage.string(forKey: Key.theme) ?? "")
            ?? .dark
        self.currency = Currency(rawValue: storage.string(forKey: Key.currency) ?? "")
            ?? .usd
        self.language = Language(rawValue: storage.string(forKey: Key.language) ?? "")
            ?? .system
        self.reduceMotion = storage.string(forKey: Key.reduceMotion) == "1"
        self.faceIDLock = (storage.string(forKey: Key.faceIDLock) ?? "1") == "1"
    }

    // MARK: - Mutations

    public func savePhase(_ phase: AppPhase) {
        self.phase = phase
        storage.set(phase.rawValue, forKey: Key.phase)
    }

    public func saveTheme(_ theme: AppTheme) {
        self.theme = theme
        storage.set(theme.rawValue, forKey: Key.theme)
    }

    public func saveCurrency(_ currency: Currency) {
        self.currency = currency
        storage.set(currency.rawValue, forKey: Key.currency)
    }

    public func saveLanguage(_ language: Language) {
        self.language = language
        storage.set(language.rawValue, forKey: Key.language)
    }

    public func saveReduceMotion(_ reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        storage.set(reduceMotion ? "1" : "0", forKey: Key.reduceMotion)
    }

    public func saveFaceIDLock(_ enabled: Bool) {
        self.faceIDLock = enabled
        storage.set(enabled ? "1" : "0", forKey: Key.faceIDLock)
    }
}

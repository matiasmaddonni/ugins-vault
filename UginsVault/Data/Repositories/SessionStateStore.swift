//
//  SessionStateStore.swift
//  UginsVault — Data layer
//
//  Concrete state store for the user's lightweight session settings
//  (phase, theme, currency, language, reduce-motion, Face ID lock,
//  preferred price source, dashboard mover threshold, manual ARS rate).
//
//  Per `.claude/Architecture.md`: SwiftUI-observable state lives in a
//  `@MainActor @Observable` state store rather than behind an Observable
//  repository protocol — this kills the protocol-level `@MainActor` that
//  used to force the entire dependency chain onto the main actor.
//
//  Persistence is `SessionStorageDataSource` (UserDefaults today —
//  synchronous + microseconds, so no actor split needed). SwiftData
//  is reserved for the collection catalogue itself.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SessionStateStore {

    // MARK: - Keys

    private enum Key {
        static let phase                  = "uv.session.phase"
        static let theme                  = "uv.session.theme"
        static let currency               = "uv.session.currency"
        static let language               = "uv.session.language"
        static let reduceMotion           = "uv.session.reduceMotion"
        static let faceIDLock             = "uv.session.faceIDLock"
        static let preferredPriceSource   = "uv.session.preferredPriceSource"
        static let moverThreshold         = "uv.session.dashboardMoverThreshold"
        static let manualARSRate          = "uv.session.manualARSRate"
    }

    // MARK: - Observable state

    public private(set) var phase:                  AppPhase
    public private(set) var theme:                  AppTheme
    public private(set) var currency:               Currency
    public private(set) var language:               Language
    public private(set) var reduceMotion:           Bool
    public private(set) var faceIDLock:             Bool
    public private(set) var preferredPriceSource:   PriceSource
    public private(set) var dashboardMoverThreshold: Decimal
    public private(set) var manualARSRate:          Decimal?

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
        self.preferredPriceSource = PriceSource(
            rawValue: storage.string(forKey: Key.preferredPriceSource) ?? ""
        ) ?? .cardkingdom
        if let raw = storage.string(forKey: Key.moverThreshold),
           let value = Decimal(string: raw) {
            self.dashboardMoverThreshold = value
        } else {
            self.dashboardMoverThreshold = Decimal(string: "1.00")!
        }
        if let raw = storage.string(forKey: Key.manualARSRate),
           let value = Decimal(string: raw),
           value > 0 {
            self.manualARSRate = value
        } else {
            self.manualARSRate = nil
        }
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

    public func savePreferredPriceSource(_ source: PriceSource) {
        self.preferredPriceSource = source
        storage.set(source.rawValue, forKey: Key.preferredPriceSource)
    }

    public func saveDashboardMoverThreshold(_ threshold: Decimal) {
        self.dashboardMoverThreshold = threshold
        storage.set("\(threshold)", forKey: Key.moverThreshold)
    }

    public func saveManualARSRate(_ rate: Decimal?) {
        self.manualARSRate = rate
        if let rate {
            storage.set("\(rate)", forKey: Key.manualARSRate)
        } else {
            storage.set(nil, forKey: Key.manualARSRate)
        }
    }
}

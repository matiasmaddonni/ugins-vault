//
//  SessionRepository.swift
//  UginsVault — Domain layer
//
//  Persists the user's lightweight session state: current phase, theme,
//  display currency, language, reduce-motion, Face ID lock. Card / stack
//  data lives in SwiftData, not here.
//
//  Exposes each value as an observable stored property so SwiftUI views
//  reading them re-render automatically when a Save method mutates them.
//

import Foundation
import Observation

@MainActor
public protocol SessionRepository: AnyObject, Observable {

    // MARK: - Observable state

    var phase:        AppPhase  { get }
    var theme:        AppTheme  { get }
    var currency:     Currency  { get }
    var language:     Language  { get }
    var reduceMotion: Bool      { get }
    var faceIDLock:   Bool      { get }

    /// Which marketplace's retail prices we show by default on Card
    /// Detail + use to feed the Dashboard aggregations. Default
    /// `.cardkingdom` (the user's reference in AR).
    var preferredPriceSource: PriceSource { get }

    /// Minimum signed USD delta a card has to move in the last 7
    /// days to qualify for the Dashboard gainers/losers lists. Lets
    /// the user hide noise from $0.10 commons.
    var dashboardMoverThreshold: Decimal { get }

    /// Optional manual override for the USD → ARS rate. `nil` means
    /// "use the dolarapi blue feed". When set, the FX layer skips the
    /// network call entirely.
    var manualARSRate: Decimal? { get }

    // MARK: - Mutations

    func savePhase(_ phase: AppPhase)
    func saveTheme(_ theme: AppTheme)
    func saveCurrency(_ currency: Currency)
    func saveLanguage(_ language: Language)
    func saveReduceMotion(_ reduceMotion: Bool)
    func saveFaceIDLock(_ enabled: Bool)
    func savePreferredPriceSource(_ source: PriceSource)
    func saveDashboardMoverThreshold(_ threshold: Decimal)
    func saveManualARSRate(_ rate: Decimal?)
}

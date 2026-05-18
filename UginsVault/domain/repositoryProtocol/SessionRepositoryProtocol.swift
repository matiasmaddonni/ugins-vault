//
//  SessionRepositoryProtocol.swift
//  UginsVault — Domain layer
//
//  Persists the user's lightweight session state: current phase, theme,
//  display currency. Card / stack data lives in SwiftData, not here.
//

import Foundation

public protocol SessionRepositoryProtocol: Sendable {

    // MARK: - Phase

    func loadPhase() -> AppPhase
    func savePhase(_ phase: AppPhase)

    // MARK: - Theme

    func loadTheme() -> AppTheme
    func saveTheme(_ theme: AppTheme)

    // MARK: - Currency

    func loadCurrency() -> Currency
    func saveCurrency(_ currency: Currency)
}

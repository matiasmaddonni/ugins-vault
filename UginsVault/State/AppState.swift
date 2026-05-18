//
//  AppState.swift
//  UginsVault
//
//  Top-level session state. Phase routing + user prefs (theme, currency).
//  Persisted to UserDefaults; SwiftData handles cards/stacks separately.
//

import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - Phase

    var phase: AppPhase {
        didSet { persist("uv.phase", phase.rawValue) }
    }

    // MARK: - Preferences

    var theme: AppTheme {
        didSet { persist("uv.theme", theme.rawValue) }
    }

    var currency: Currency {
        didSet { persist("uv.currency", currency.rawValue) }
    }

    // MARK: - Init

    init() {
        let phaseRaw = UserDefaults.standard.string(forKey: "uv.phase") ?? AppPhase.splash.rawValue
        self.phase = AppPhase(rawValue: phaseRaw) ?? .splash

        let themeRaw = UserDefaults.standard.string(forKey: "uv.theme") ?? AppTheme.dark.rawValue
        self.theme = AppTheme(rawValue: themeRaw) ?? .dark

        let curRaw = UserDefaults.standard.string(forKey: "uv.currency") ?? Currency.usd.rawValue
        self.currency = Currency(rawValue: curRaw) ?? .usd
    }

    // MARK: - Actions

    func advanceFromSplash() {
        // If user has previously authenticated this device session, skip login.
        // For now we always go through login.
        phase = .login
    }

    func didAuthenticate() {
        phase = .home
    }

    func resetToSplash() {
        phase = .splash
    }

    // MARK: - Persistence helper

    private func persist(_ key: String, _ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

// MARK: - Currency

enum Currency: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case ars = "ARS"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .ars: return "AR$"
        }
    }
}

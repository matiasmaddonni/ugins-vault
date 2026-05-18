//
//  MockSessionRepository.swift
//  UginsVaultTests
//

import Foundation
@testable import UginsVault

final class MockSessionRepository: SessionRepositoryProtocol, @unchecked Sendable {

    // Stubs
    var stubbedPhase: AppPhase = .splash
    var stubbedTheme: AppTheme = .dark
    var stubbedCurrency: Currency = .usd

    // Spies
    private(set) var savedPhase: AppPhase?
    private(set) var savedTheme: AppTheme?
    private(set) var savedCurrency: Currency?
    private(set) var savePhaseCallCount: Int = 0

    func loadPhase() -> AppPhase { stubbedPhase }
    func savePhase(_ phase: AppPhase) {
        savedPhase = phase
        stubbedPhase = phase
        savePhaseCallCount += 1
    }

    func loadTheme() -> AppTheme { stubbedTheme }
    func saveTheme(_ theme: AppTheme) {
        savedTheme = theme
        stubbedTheme = theme
    }

    func loadCurrency() -> Currency { stubbedCurrency }
    func saveCurrency(_ currency: Currency) {
        savedCurrency = currency
        stubbedCurrency = currency
    }
}

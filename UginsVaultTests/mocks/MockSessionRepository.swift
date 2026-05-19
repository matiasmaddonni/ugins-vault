//
//  MockSessionRepository.swift
//  UginsVaultTests
//

import Foundation
import Observation
@testable import UginsVault

@Observable
final class MockSessionRepository: SessionRepository, @unchecked Sendable {

    // Stubs
    @ObservationIgnored var stubbedPhase: AppPhase = .splash
    @ObservationIgnored var stubbedTheme: AppTheme = .dark
    @ObservationIgnored var stubbedCurrency: Currency = .usd

    // Spies
    @ObservationIgnored private(set) var savedPhase: AppPhase?
    @ObservationIgnored private(set) var savedTheme: AppTheme?
    @ObservationIgnored private(set) var savedCurrency: Currency?
    @ObservationIgnored private(set) var savePhaseCallCount: Int = 0

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

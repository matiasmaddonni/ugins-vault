//
//  MockSessionRepository.swift
//  UginsVaultTests
//

import Foundation
import Observation
@testable import UginsVault

@Observable
final class MockSessionRepository: SessionRepository, @unchecked Sendable {

    // Observable state (also doubles as stub setter)
    var phase:        AppPhase  = .splash
    var theme:        AppTheme  = .dark
    var currency:     Currency  = .usd
    var language:     Language  = .system
    var reduceMotion: Bool      = false
    var faceIDLock:   Bool      = true

    // Spies
    @ObservationIgnored private(set) var savedPhase:        AppPhase?
    @ObservationIgnored private(set) var savedTheme:        AppTheme?
    @ObservationIgnored private(set) var savedCurrency:     Currency?
    @ObservationIgnored private(set) var savedLanguage:     Language?
    @ObservationIgnored private(set) var savedReduceMotion: Bool?
    @ObservationIgnored private(set) var savedFaceIDLock:   Bool?
    @ObservationIgnored private(set) var savePhaseCallCount: Int = 0

    // Mutations

    func savePhase(_ phase: AppPhase) {
        savedPhase = phase
        self.phase = phase
        savePhaseCallCount += 1
    }

    func saveTheme(_ theme: AppTheme) {
        savedTheme = theme
        self.theme = theme
    }

    func saveCurrency(_ currency: Currency) {
        savedCurrency = currency
        self.currency = currency
    }

    func saveLanguage(_ language: Language) {
        savedLanguage = language
        self.language = language
    }

    func saveReduceMotion(_ reduceMotion: Bool) {
        savedReduceMotion = reduceMotion
        self.reduceMotion = reduceMotion
    }

    func saveFaceIDLock(_ enabled: Bool) {
        savedFaceIDLock = enabled
        self.faceIDLock = enabled
    }
}

//
//  HomeViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {

    @Test("Init reads theme + currency from the session repository")
    func initReadsPrefs() {
        let session = MockSessionRepository()
        session.stubbedTheme = .light
        session.stubbedCurrency = .eur

        let sut = HomeViewModel(sessionRepository: session)

        #expect(sut.theme == .light)
        #expect(sut.currency == .eur)
    }

    @Test("toggleTheme() flips the value and persists it")
    func toggleThemeFlipsAndPersists() {
        let session = MockSessionRepository()
        session.stubbedTheme = .dark
        let sut = HomeViewModel(sessionRepository: session)

        sut.toggleTheme()

        #expect(sut.theme == .light)
        #expect(session.savedTheme == .light)

        sut.toggleTheme()

        #expect(sut.theme == .dark)
        #expect(session.savedTheme == .dark)
    }

    @Test("setCurrency persists the new value")
    func setCurrencyPersists() {
        let session = MockSessionRepository()
        let sut = HomeViewModel(sessionRepository: session)

        sut.setCurrency(.ars)

        #expect(sut.currency == .ars)
        #expect(session.savedCurrency == .ars)
    }

    @Test("Placeholder totals start empty")
    func placeholderTotalsZero() {
        let session = MockSessionRepository()
        let sut = HomeViewModel(sessionRepository: session)

        #expect(sut.cardCount == 0)
        #expect(sut.totalValue == 0)
    }
}

//
//  CollectionViewModelTests.swift
//  UginsVaultTests
//

import Testing
@testable import UginsVault

@Suite("CollectionViewModel")
@MainActor
struct CollectionViewModelTests {

    @Test("Init reads currency from the session repository")
    func initReadsCurrency() {
        let session = MockSessionRepository()
        session.currency = .eur
        let sut = CollectionViewModel(sessionRepository: session)

        #expect(sut.currency == .eur)
    }

    @Test("Placeholder totals start empty")
    func placeholderTotalsAreZero() {
        let session = MockSessionRepository()
        let sut = CollectionViewModel(sessionRepository: session)

        #expect(sut.cardCount == 0)
        #expect(sut.totalValue == 0)
        #expect(sut.searchQuery == "")
    }

    @Test("refreshPreferences picks up a new currency from the session repository")
    func refreshPreferencesUpdatesCurrency() {
        let session = MockSessionRepository()
        session.currency = .usd
        let sut = CollectionViewModel(sessionRepository: session)

        session.currency = .ars
        sut.refreshPreferences()

        #expect(sut.currency == .ars)
    }
}

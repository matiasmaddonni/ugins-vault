//
//  CurrencyUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("CurrencyUseCases")
@MainActor
struct CurrencyUseCasesTests {

    @Test("GetCurrency reads from the session repository")
    func getReadsFromSession() {
        let session = MockSessionRepository()
        session.currency = .eur
        let sut = GetCurrencyUseCase(sessionRepository: session)

        #expect(sut.execute() == .eur)
    }

    @Test("SetCurrency writes to the session repository")
    func setWritesToSession() {
        let session = MockSessionRepository()
        let sut = SetCurrencyUseCase(sessionRepository: session)

        sut.execute(.ars)

        #expect(session.savedCurrency == .ars)
    }
}

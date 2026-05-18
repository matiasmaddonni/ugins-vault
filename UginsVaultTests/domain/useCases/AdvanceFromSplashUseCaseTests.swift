//
//  AdvanceFromSplashUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("AdvanceFromSplashUseCase")
struct AdvanceFromSplashUseCaseTests {

    @Test("Returns .login and persists it")
    func returnsLogin() {
        let session = MockSessionRepository()
        let sut = AdvanceFromSplashUseCase(sessionRepository: session)

        let next = sut.execute()

        #expect(next == .login)
        #expect(session.savedPhase == .login)
    }

    @Test("Persists even when current phase is already .login")
    func idempotent() {
        let session = MockSessionRepository()
        session.stubbedPhase = .login
        let sut = AdvanceFromSplashUseCase(sessionRepository: session)

        let next = sut.execute()

        #expect(next == .login)
        #expect(session.savePhaseCallCount == 1)
    }
}

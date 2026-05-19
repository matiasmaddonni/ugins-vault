//
//  AdvanceFromSplashUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("AdvanceFromSplashUseCase")
struct AdvanceFromSplashUseCaseTests {

    @Test("Routes to .login when Face ID lock is enabled")
    func routesToLoginWhenLocked() {
        let session = MockSessionRepository()
        session.faceIDLock = true
        let sut = AdvanceFromSplashUseCase(sessionRepository: session)

        let next = sut.execute()

        #expect(next == .login)
        #expect(session.savedPhase == .login)
    }

    @Test("Routes straight to .home when Face ID lock is disabled")
    func routesToHomeWhenUnlocked() {
        let session = MockSessionRepository()
        session.faceIDLock = false
        let sut = AdvanceFromSplashUseCase(sessionRepository: session)

        let next = sut.execute()

        #expect(next == .home)
        #expect(session.savedPhase == .home)
    }

    @Test("Persists even when current phase is already .login")
    func idempotent() {
        let session = MockSessionRepository()
        session.phase = .login
        session.faceIDLock = true
        let sut = AdvanceFromSplashUseCase(sessionRepository: session)

        let next = sut.execute()

        #expect(next == .login)
        #expect(session.savePhaseCallCount == 1)
    }
}

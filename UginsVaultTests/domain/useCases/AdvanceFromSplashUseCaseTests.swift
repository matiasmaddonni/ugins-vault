//
//  AdvanceFromSplashUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("AdvanceFromSplashUseCase")
@MainActor
struct AdvanceFromSplashUseCaseTests {

    private func makeSUT(
        session: MockSessionRepository,
        account: MockAccountRepository
    ) -> AdvanceFromSplashUseCase {
        AdvanceFromSplashUseCase(sessionRepository: session, accountRepository: account)
    }

    @Test("Routes to .accountLogin when there is no backend session")
    func routesToAccountLoginWhenSignedOut() async {
        let session = MockSessionRepository()
        let account = MockAccountRepository()
        account.restoresToSignedIn = false
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .accountLogin)
        #expect(account.restoreCallCount == 1)
        // Account gate is not persisted.
        #expect(session.savePhaseCallCount == 0)
    }

    @Test("Routes to .login when signed in and Face ID lock is enabled")
    func routesToLoginWhenLocked() async {
        let session = MockSessionRepository()
        session.faceIDLock = true
        let account = MockAccountRepository()
        account.restoresToSignedIn = true
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .login)
        #expect(session.savedPhase == .login)
    }

    @Test("Routes straight to .home when signed in and Face ID lock is disabled")
    func routesToHomeWhenUnlocked() async {
        let session = MockSessionRepository()
        session.faceIDLock = false
        let account = MockAccountRepository()
        account.restoresToSignedIn = true
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .home)
        #expect(session.savedPhase == .home)
    }

    @Test("Persists exactly once when signed in")
    func persistsOnce() async {
        let session = MockSessionRepository()
        session.phase = .login
        session.faceIDLock = true
        let account = MockAccountRepository()
        account.restoresToSignedIn = true
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .login)
        #expect(session.savePhaseCallCount == 1)
    }
}

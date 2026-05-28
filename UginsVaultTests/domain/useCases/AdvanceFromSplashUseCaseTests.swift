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
        session: SessionStateStore,
        account: MockAccountRepository
    ) -> AdvanceFromSplashUseCase {
        AdvanceFromSplashUseCase(sessionRepository: session, accountRepository: account)
    }

    @Test("Routes to .accountLogin when there is no backend session")
    func routesToAccountLoginWhenSignedOut() async {
        let session = SessionStateStore(storage: MockSessionStorage())
        let account = MockAccountRepository()
        account.restoresToSignedIn = false
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .accountLogin)
        #expect(account.restoreCallCount == 1)
        // Account gate is not persisted — phase stays at its initial value.
        #expect(session.phase == .splash)
    }

    @Test("Routes to .login when signed in and Face ID lock is enabled")
    func routesToLoginWhenLocked() async {
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveFaceIDLock(true)
        let account = MockAccountRepository()
        account.restoresToSignedIn = true
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .login)
        #expect(session.phase == .login)
    }

    @Test("Routes straight to .home when signed in and Face ID lock is disabled")
    func routesToHomeWhenUnlocked() async {
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveFaceIDLock(false)
        let account = MockAccountRepository()
        account.restoresToSignedIn = true
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .home)
        #expect(session.phase == .home)
    }

    @Test("Persists exactly once when signed in")
    func persistsOnce() async {
        let session = SessionStateStore(storage: MockSessionStorage())
        session.savePhase(.login)
        session.saveFaceIDLock(true)
        let account = MockAccountRepository()
        account.restoresToSignedIn = true
        let sut = makeSUT(session: session, account: account)

        let next = await sut.execute()

        #expect(next == .login)
        #expect(session.phase == .login)
    }
}

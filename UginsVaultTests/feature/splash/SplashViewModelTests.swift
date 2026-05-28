//
//  SplashViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@Suite("SplashViewModel")
@MainActor
struct SplashViewModelTests {

    private func makeUseCase(
        session: SessionStateStore,
        signedIn: Bool
    ) -> AdvanceFromSplashUseCase {
        let account = MockAccountRepository()
        account.restoresToSignedIn = signedIn
        return AdvanceFromSplashUseCase(sessionRepository: session, accountRepository: account)
    }

    @Test("start() flips didAppear and (after hold) advances a signed-in user to .login")
    func startAdvances() async throws {
        let session = SessionStateStore(storage: MockSessionStorage())
        let useCase = makeUseCase(session: session, signedIn: true)

        var advancedTo: AppPhase?
        let sut = SplashViewModel(
            advanceFromSplashUseCase: useCase,
            onAdvance: { advancedTo = $0 },
            holdDuration: .milliseconds(50)
        )

        #expect(sut.didAppear == false)

        sut.start()
        #expect(sut.didAppear == true)

        try await Task.sleep(for: .milliseconds(200))

        #expect(advancedTo == .login)
        #expect(session.phase == .login)
    }

    @Test("start() advances a signed-out user to .accountLogin")
    func startAdvancesToAccountLogin() async throws {
        let session = SessionStateStore(storage: MockSessionStorage())
        let useCase = makeUseCase(session: session, signedIn: false)

        var advancedTo: AppPhase?
        let sut = SplashViewModel(
            advanceFromSplashUseCase: useCase,
            onAdvance: { advancedTo = $0 },
            holdDuration: .milliseconds(50)
        )

        sut.start()
        try await Task.sleep(for: .milliseconds(200))

        #expect(advancedTo == .accountLogin)
    }

    @Test("start() is idempotent — second call doesn't fire onAdvance twice")
    func startIsIdempotent() async throws {
        let session = SessionStateStore(storage: MockSessionStorage())
        let useCase = makeUseCase(session: session, signedIn: true)

        var advanceCount = 0
        let sut = SplashViewModel(
            advanceFromSplashUseCase: useCase,
            onAdvance: { _ in advanceCount += 1 },
            holdDuration: .milliseconds(30)
        )

        sut.start()
        sut.start()
        sut.start()

        try await Task.sleep(for: .milliseconds(150))

        #expect(advanceCount == 1)
    }
}

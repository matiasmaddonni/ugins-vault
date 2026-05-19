//
//  SplashViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@Suite("SplashViewModel")
@MainActor
struct SplashViewModelTests {

    @Test("start() flips didAppear and (after hold) calls onAdvance with .login")
    func startAdvances() async throws {
        let session = MockSessionRepository()
        let useCase = AdvanceFromSplashUseCase(sessionRepository: session)

        var advancedTo: AppPhase?
        let sut = SplashViewModel(
            advanceFromSplashUseCase: useCase,
            onAdvance: { advancedTo = $0 },
            holdDuration: .milliseconds(50)
        )

        #expect(sut.didAppear == false)

        sut.start()
        #expect(sut.didAppear == true)

        try await Task.sleep(for: .milliseconds(150))

        #expect(advancedTo == .login)
        #expect(session.savedPhase == .login)
    }

    @Test("start() is idempotent — second call doesn't fire onAdvance twice")
    func startIsIdempotent() async throws {
        let session = MockSessionRepository()
        let useCase = AdvanceFromSplashUseCase(sessionRepository: session)

        var advanceCount = 0
        let sut = SplashViewModel(
            advanceFromSplashUseCase: useCase,
            onAdvance: { _ in advanceCount += 1 },
            holdDuration: .milliseconds(30)
        )

        sut.start()
        sut.start()
        sut.start()

        try await Task.sleep(for: .milliseconds(120))

        #expect(advanceCount == 1)
    }
}

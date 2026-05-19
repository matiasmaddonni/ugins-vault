//
//  RootViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@Suite("RootViewModel")
@MainActor
struct RootViewModelTests {

    @Test("Initial phase comes from the session via the use case")
    func initialPhase() {
        let session = MockSessionRepository()
        session.phase = .login
        let sut = RootViewModel(
            getCurrentPhaseUseCase: GetCurrentPhaseUseCase(sessionRepository: session)
        )

        #expect(sut.phase == .login)
    }

    @Test("transition(to:) updates the published phase")
    func transitionUpdates() {
        let session = MockSessionRepository()
        session.phase = .splash
        let sut = RootViewModel(
            getCurrentPhaseUseCase: GetCurrentPhaseUseCase(sessionRepository: session)
        )

        sut.transition(to: .login)
        #expect(sut.phase == .login)

        sut.transition(to: .home)
        #expect(sut.phase == .home)
    }

    @Test("transition(to:) is a no-op when the phase is unchanged")
    func transitionIdempotent() {
        let session = MockSessionRepository()
        session.phase = .home
        let sut = RootViewModel(
            getCurrentPhaseUseCase: GetCurrentPhaseUseCase(sessionRepository: session)
        )

        sut.transition(to: .home)
        #expect(sut.phase == .home)
    }
}

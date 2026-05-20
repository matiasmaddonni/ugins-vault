//
//  RootViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@Suite("RootViewModel")
@MainActor
struct RootViewModelTests {

    @Test("Always starts at .splash so the launch gates re-run")
    func initialPhase() {
        let sut = RootViewModel()
        #expect(sut.phase == .splash)
    }

    @Test("transition(to:) updates the phase")
    func transitionUpdates() {
        let sut = RootViewModel()

        sut.transition(to: .accountLogin)
        #expect(sut.phase == .accountLogin)

        sut.transition(to: .login)
        #expect(sut.phase == .login)

        sut.transition(to: .home)
        #expect(sut.phase == .home)
    }

    @Test("transition(to:) is a no-op when the phase is unchanged")
    func transitionIdempotent() {
        let sut = RootViewModel()

        sut.transition(to: .home)
        #expect(sut.phase == .home)

        sut.transition(to: .home)
        #expect(sut.phase == .home)
    }
}

//
//  GetCurrentPhaseUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("GetCurrentPhaseUseCase")
struct GetCurrentPhaseUseCaseTests {

    @Test("Returns whatever the session reports")
    func returnsSessionValue() {
        let session = MockSessionRepository()
        session.phase = .home
        let sut = GetCurrentPhaseUseCase(sessionRepository: session)

        #expect(sut.execute() == .home)
    }

    @Test("Defaults to .splash when nothing persisted")
    func defaultsToSplash() {
        let session = MockSessionRepository() // default stub is .splash
        let sut = GetCurrentPhaseUseCase(sessionRepository: session)

        #expect(sut.execute() == .splash)
    }
}

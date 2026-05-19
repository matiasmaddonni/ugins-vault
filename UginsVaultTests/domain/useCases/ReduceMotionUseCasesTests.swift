//
//  ReduceMotionUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("ReduceMotionUseCases")
@MainActor
struct ReduceMotionUseCasesTests {

    @Test("GetReduceMotion reads from the session repository")
    func getReadsFromSession() {
        let session = MockSessionRepository()
        session.reduceMotion = true
        let sut = GetReduceMotionUseCase(sessionRepository: session)

        #expect(sut.execute() == true)
    }

    @Test("SetReduceMotion writes to the session repository")
    func setWritesToSession() {
        let session = MockSessionRepository()
        let sut = SetReduceMotionUseCase(sessionRepository: session)

        sut.execute(true)

        #expect(session.savedReduceMotion == true)
    }
}

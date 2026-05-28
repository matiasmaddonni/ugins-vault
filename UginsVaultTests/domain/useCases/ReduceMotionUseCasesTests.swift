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
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveReduceMotion(true)
        let sut = GetReduceMotionUseCase(sessionRepository: session)

        #expect(sut.execute() == true)
    }

    @Test("SetReduceMotion writes to the session repository")
    func setWritesToSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        let sut = SetReduceMotionUseCase(sessionRepository: session)

        sut.execute(true)

        #expect(session.reduceMotion == true)
    }
}

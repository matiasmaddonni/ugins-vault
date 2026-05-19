//
//  FaceIDLockUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("FaceIDLockUseCases")
struct FaceIDLockUseCasesTests {

    @Test("GetFaceIDLock reads from the session repository")
    func getReadsFromSession() {
        let session = MockSessionRepository()
        session.faceIDLock = false
        let sut = GetFaceIDLockUseCase(sessionRepository: session)

        #expect(sut.execute() == false)
    }

    @Test("SetFaceIDLock writes to the session repository")
    func setWritesToSession() {
        let session = MockSessionRepository()
        let sut = SetFaceIDLockUseCase(sessionRepository: session)

        sut.execute(false)

        #expect(session.savedFaceIDLock == false)
    }
}

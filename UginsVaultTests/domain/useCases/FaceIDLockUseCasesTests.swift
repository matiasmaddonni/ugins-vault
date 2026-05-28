//
//  FaceIDLockUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("FaceIDLockUseCases")
@MainActor
struct FaceIDLockUseCasesTests {

    @Test("GetFaceIDLock reads from the session repository")
    func getReadsFromSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveFaceIDLock(false)
        let sut = GetFaceIDLockUseCase(sessionRepository: session)

        #expect(sut.execute() == false)
    }

    @Test("SetFaceIDLock writes to the session repository")
    func setWritesToSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        let sut = SetFaceIDLockUseCase(sessionRepository: session)

        sut.execute(false)

        #expect(session.faceIDLock == false)
    }
}

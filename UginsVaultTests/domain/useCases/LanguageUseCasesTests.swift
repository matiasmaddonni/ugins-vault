//
//  LanguageUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("LanguageUseCases")
@MainActor
struct LanguageUseCasesTests {

    @Test("GetPreferredLanguage reads from the session repository")
    func getReadsFromSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveLanguage(.spanish)
        let sut = GetPreferredLanguageUseCase(sessionRepository: session)

        #expect(sut.execute() == .spanish)
    }

    @Test("SetPreferredLanguage writes to the session repository")
    func setWritesToSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        let sut = SetPreferredLanguageUseCase(sessionRepository: session)

        sut.execute(.english)

        #expect(session.language == .english)
    }
}

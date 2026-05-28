//
//  ThemeUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("ThemeUseCases")
@MainActor
struct ThemeUseCasesTests {

    @Test("GetTheme reads from the session repository")
    func getThemeReadsFromSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveTheme(.light)
        let sut = GetThemeUseCase(sessionRepository: session)

        #expect(sut.execute() == .light)
    }

    @Test("SetTheme writes to the session repository")
    func setThemeWritesToSession() {
        let session = SessionStateStore(storage: MockSessionStorage())
        let sut = SetThemeUseCase(sessionRepository: session)

        sut.execute(.system)

        #expect(session.theme == .system)
    }
}

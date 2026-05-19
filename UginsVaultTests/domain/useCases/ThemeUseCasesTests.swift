//
//  ThemeUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("ThemeUseCases")
struct ThemeUseCasesTests {

    @Test("GetTheme reads from the session repository")
    func getThemeReadsFromSession() {
        let session = MockSessionRepository()
        session.theme = .light
        let sut = GetThemeUseCase(sessionRepository: session)

        #expect(sut.execute() == .light)
    }

    @Test("SetTheme writes to the session repository")
    func setThemeWritesToSession() {
        let session = MockSessionRepository()
        let sut = SetThemeUseCase(sessionRepository: session)

        sut.execute(.system)

        #expect(session.savedTheme == .system)
    }
}

//
//  SessionRepositoryTests.swift
//  UginsVaultTests — Data
//

import Testing
@testable import UginsVault

@Suite("SessionRepository")
struct SessionRepositoryTests {

    @Test("loadPhase defaults to .splash when storage is empty")
    func defaultPhase() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.phase == .splash)
    }

    @Test("savePhase + loadPhase round-trips the value")
    func phaseRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.savePhase(.home)

        #expect(sut.phase == .home)
    }

    @Test("loadTheme defaults to .dark when storage is empty")
    func defaultTheme() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.theme == .dark)
    }

    @Test("saveTheme + loadTheme round-trips the value")
    func themeRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveTheme(.light)

        #expect(sut.theme == .light)
    }

    @Test("loadCurrency defaults to .usd when storage is empty")
    func defaultCurrency() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.currency == .usd)
    }

    @Test("saveCurrency + loadCurrency round-trips the value")
    func currencyRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveCurrency(.ars)

        #expect(sut.currency == .ars)
    }

    @Test("Malformed raw values fall back to defaults")
    func malformedFallbacks() {
        let storage = MockSessionStorage()
        storage.set("not-a-real-phase", forKey: "uv.session.phase")
        storage.set("???",                forKey: "uv.session.theme")
        storage.set("XYZ",                forKey: "uv.session.currency")
        storage.set("klingon",            forKey: "uv.session.language")
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.phase == .splash)
        #expect(sut.theme == .dark)
        #expect(sut.currency == .usd)
        #expect(sut.language == .system)
    }

    // MARK: - Language

    @Test("loadLanguage defaults to .system when storage is empty")
    func defaultLanguage() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.language == .system)
    }

    @Test("saveLanguage + loadLanguage round-trips the value")
    func languageRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveLanguage(.spanish)

        #expect(sut.language == .spanish)
    }

    // MARK: - Reduce motion

    @Test("loadReduceMotion defaults to false when storage is empty")
    func defaultReduceMotion() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.reduceMotion == false)
    }

    @Test("saveReduceMotion + loadReduceMotion round-trips the value")
    func reduceMotionRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveReduceMotion(true)

        #expect(sut.reduceMotion == true)
    }

    // MARK: - Face ID lock

    @Test("loadFaceIDLock defaults to true when storage is empty")
    func defaultFaceIDLock() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.faceIDLock == true)
    }

    @Test("saveFaceIDLock + loadFaceIDLock round-trips the value")
    func faceIDLockRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveFaceIDLock(false)

        #expect(sut.faceIDLock == false)
    }
}

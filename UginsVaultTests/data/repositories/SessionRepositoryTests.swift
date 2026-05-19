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

        #expect(sut.loadPhase() == .splash)
    }

    @Test("savePhase + loadPhase round-trips the value")
    func phaseRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.savePhase(.home)

        #expect(sut.loadPhase() == .home)
    }

    @Test("loadTheme defaults to .dark when storage is empty")
    func defaultTheme() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.loadTheme() == .dark)
    }

    @Test("saveTheme + loadTheme round-trips the value")
    func themeRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveTheme(.light)

        #expect(sut.loadTheme() == .light)
    }

    @Test("loadCurrency defaults to .usd when storage is empty")
    func defaultCurrency() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.loadCurrency() == .usd)
    }

    @Test("saveCurrency + loadCurrency round-trips the value")
    func currencyRoundTrip() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsSessionRepository(storage: storage)

        sut.saveCurrency(.ars)

        #expect(sut.loadCurrency() == .ars)
    }

    @Test("Malformed raw values fall back to defaults")
    func malformedFallbacks() {
        let storage = MockSessionStorage()
        storage.set("not-a-real-phase", forKey: "uv.session.phase")
        storage.set("???",                forKey: "uv.session.theme")
        storage.set("XYZ",                forKey: "uv.session.currency")
        let sut = UserDefaultsSessionRepository(storage: storage)

        #expect(sut.loadPhase() == .splash)
        #expect(sut.loadTheme() == .dark)
        #expect(sut.loadCurrency() == .usd)
    }
}

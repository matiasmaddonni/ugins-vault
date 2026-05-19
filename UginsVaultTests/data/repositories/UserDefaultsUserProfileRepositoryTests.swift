//
//  UserDefaultsUserProfileRepositoryTests.swift
//  UginsVaultTests — Data
//

import Testing
@testable import UginsVault

@Suite("UserDefaultsUserProfileRepository")
struct UserDefaultsUserProfileRepositoryTests {

    @Test("load returns the default profile when storage is empty")
    func loadDefaultsWhenEmpty() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsUserProfileRepository(storage: storage)

        let profile = sut.profile

        #expect(profile == .default)
    }

    @Test("save then load round-trips the profile")
    func saveLoadRoundTrips() {
        let storage = MockSessionStorage()
        let sut = UserDefaultsUserProfileRepository(storage: storage)

        let next = UserProfile(name: "Tomás", monogramTint: .lavender, memberSince: 2019)
        sut.save(next)

        #expect(sut.profile == next)
    }

    @Test("Malformed JSON falls back to the default profile")
    func malformedFallsBack() {
        let storage = MockSessionStorage()
        storage.set("not json", forKey: "uv.profile")
        let sut = UserDefaultsUserProfileRepository(storage: storage)

        #expect(sut.profile == .default)
    }
}

//
//  UserProfileUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("UserProfileUseCases")
@MainActor
struct UserProfileUseCasesTests {

    @Test("GetUserProfile reads the persisted profile")
    func getReadsPersistedProfile() {
        let repo = MockUserProfileRepository()
        repo.profile = UserProfile(name: "Tomás", monogramTint: .lavender, memberSince: 2019)
        let sut = GetUserProfileUseCase(userProfileRepository: repo)

        let profile = sut.execute()

        #expect(profile.name == "Tomás")
        #expect(profile.monogramTint == .lavender)
        #expect(profile.memberSince == 2019)
    }

    @Test("UpdateUserProfile saves the new profile")
    func updateSavesNewProfile() {
        let repo = MockUserProfileRepository()
        let sut = UpdateUserProfileUseCase(userProfileRepository: repo)

        let next = UserProfile(name: "Matías", monogramTint: .verdant, memberSince: 2026)
        sut.execute(next)

        #expect(repo.savedProfile == next)
        #expect(repo.saveCallCount == 1)
    }

    @Test("UserProfile.monogram returns the uppercased first letter")
    func monogramReturnsFirstLetter() {
        let profile = UserProfile(name: "matías", monogramTint: .gold, memberSince: 2026)
        #expect(profile.monogram == "M")
    }

    @Test("UserProfile.monogram defaults to · when name is empty")
    func monogramFallsBackWhenNameEmpty() {
        let profile = UserProfile(name: "   ", monogramTint: .gold, memberSince: 2026)
        #expect(profile.monogram == "·")
    }
}

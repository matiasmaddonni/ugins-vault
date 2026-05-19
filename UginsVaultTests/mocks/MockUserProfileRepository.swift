//
//  MockUserProfileRepository.swift
//  UginsVaultTests
//

import Foundation
import Observation
@testable import UginsVault

@Observable
final class MockUserProfileRepository: UserProfileRepository, @unchecked Sendable {

    var profile: UserProfile = .default

    @ObservationIgnored private(set) var savedProfile: UserProfile?
    @ObservationIgnored private(set) var saveCallCount: Int = 0

    func save(_ profile: UserProfile) {
        savedProfile = profile
        self.profile = profile
        saveCallCount += 1
    }
}

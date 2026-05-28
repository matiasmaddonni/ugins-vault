//
//  UpdateUserProfileUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class UpdateUserProfileUseCase {

    private let userProfileRepository: UserProfileStore

    public init(userProfileRepository: UserProfileStore) {
        self.userProfileRepository = userProfileRepository
    }

    public func execute(_ profile: UserProfile) {
        userProfileRepository.save(profile)
    }
}

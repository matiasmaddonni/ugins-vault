//
//  UpdateUserProfileUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

public final class UpdateUserProfileUseCase {

    private let userProfileRepository: UserProfileRepository

    public init(userProfileRepository: UserProfileRepository) {
        self.userProfileRepository = userProfileRepository
    }

    public func execute(_ profile: UserProfile) {
        userProfileRepository.save(profile)
    }
}

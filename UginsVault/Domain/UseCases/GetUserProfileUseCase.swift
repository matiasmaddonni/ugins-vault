//
//  GetUserProfileUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetUserProfileUseCase {

    private let userProfileRepository: UserProfileRepository

    public init(userProfileRepository: UserProfileRepository) {
        self.userProfileRepository = userProfileRepository
    }

    public func execute() -> UserProfile {
        userProfileRepository.profile
    }
}

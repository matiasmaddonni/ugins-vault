//
//  GetUserProfileUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetUserProfileUseCase {

    private let userProfileRepository: UserProfileStore

    public init(userProfileRepository: UserProfileStore) {
        self.userProfileRepository = userProfileRepository
    }

    public func execute() -> UserProfile {
        userProfileRepository.profile
    }
}

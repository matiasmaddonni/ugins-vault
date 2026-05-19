//
//  GetPreferredLanguageUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

public final class GetPreferredLanguageUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Language {
        sessionRepository.language
    }
}

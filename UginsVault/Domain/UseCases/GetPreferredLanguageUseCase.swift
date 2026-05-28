//
//  GetPreferredLanguageUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetPreferredLanguageUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Language {
        sessionRepository.language
    }
}

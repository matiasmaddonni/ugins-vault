//
//  SetPreferredLanguageUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetPreferredLanguageUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ language: Language) {
        sessionRepository.saveLanguage(language)
    }
}

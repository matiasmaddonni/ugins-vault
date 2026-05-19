//
//  SetThemeUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetThemeUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ theme: AppTheme) {
        sessionRepository.saveTheme(theme)
    }
}

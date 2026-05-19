//
//  GetThemeUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetThemeUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> AppTheme {
        sessionRepository.theme
    }
}

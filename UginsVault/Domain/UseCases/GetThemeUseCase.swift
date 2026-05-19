//
//  GetThemeUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

public final class GetThemeUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> AppTheme {
        sessionRepository.theme
    }
}

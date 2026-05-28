//
//  GetThemeUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetThemeUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> AppTheme {
        sessionRepository.theme
    }
}

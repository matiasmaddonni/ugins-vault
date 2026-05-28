//
//  SetThemeUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetThemeUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ theme: AppTheme) {
        sessionRepository.saveTheme(theme)
    }
}

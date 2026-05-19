//
//  AdvanceFromSplashUseCase.swift
//  UginsVault — Domain layer
//
//  Transitions out of the splash screen. Currently always routes to `.login`;
//  future iterations may skip login when a recent authentication is cached.
//

import Foundation

public final class AdvanceFromSplashUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    @discardableResult
    public func execute() -> AppPhase {
        // Skip login entirely when the user has disabled Face ID lock in Settings.
        let next: AppPhase = sessionRepository.faceIDLock ? .login : .home
        sessionRepository.savePhase(next)
        return next
    }
}

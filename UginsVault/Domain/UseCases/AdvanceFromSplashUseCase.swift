//
//  AdvanceFromSplashUseCase.swift
//  UginsVault — Domain layer
//
//  Transitions out of the splash screen. Currently always routes to `.login`;
//  future iterations may skip login when a recent authentication is cached.
//

import Foundation

public final class AdvanceFromSplashUseCase: Sendable {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    @discardableResult
    public func execute() -> AppPhase {
        let next: AppPhase = .login
        sessionRepository.savePhase(next)
        return next
    }
}

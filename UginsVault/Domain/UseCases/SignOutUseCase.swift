//
//  SignOutUseCase.swift
//  UginsVault — Domain layer
//
//  Resets the session back to the login phase. Used by Settings and by the
//  Login screen's "Skip (dev)" reset flow.
//

import Foundation

public final class SignOutUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() {
        sessionRepository.savePhase(.login)
    }
}

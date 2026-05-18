//
//  SignOutUseCase.swift
//  UginsVault — Domain layer
//
//  Resets the session back to the login phase. Used by Settings and by the
//  Login screen's "Skip (dev)" reset flow.
//

import Foundation

public final class SignOutUseCase: Sendable {

    private let sessionRepository: SessionRepositoryProtocol

    public init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    public func execute() {
        sessionRepository.savePhase(.login)
    }
}

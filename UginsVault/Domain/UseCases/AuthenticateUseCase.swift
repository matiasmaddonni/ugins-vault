//
//  AuthenticateUseCase.swift
//  UginsVault — Domain layer
//
//  Triggers a biometric authentication attempt. On success, marks the session
//  as authenticated (moves phase to `.home`). Returns the outcome so the
//  caller can react to cancellation / fallback / failure paths.
//

import Foundation

@MainActor
public final class AuthenticateUseCase {

    private let authRepository: AuthRepository
    private let sessionRepository: SessionRepository

    public init(
        authRepository: AuthRepository,
        sessionRepository: SessionRepository
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
    }

    /// Executes the authentication flow.
    /// - Parameter reason: Reason string shown in the system prompt.
    /// - Returns: The outcome. `.success` is the only case that mutates session state.
    @discardableResult
    public func execute(reason: String) async -> AuthOutcome {
        let outcome = await authRepository.authenticate(reason: reason)
        if case .success = outcome {
            sessionRepository.savePhase(.home)
        }
        return outcome
    }
}

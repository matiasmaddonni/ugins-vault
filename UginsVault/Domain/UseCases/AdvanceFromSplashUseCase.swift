//
//  AdvanceFromSplashUseCase.swift
//  UginsVault — Domain layer
//
//  Resolves the post-splash phase. Runs on every cold launch so the gates
//  re-evaluate (this is what makes Face ID re-lock between launches):
//
//   1. No restorable backend session  → `.accountLogin`.
//   2. Signed in, Face ID lock on      → `.login` (local biometric gate).
//   3. Signed in, Face ID lock off     → `.home`.
//

import Foundation

@MainActor
public final class AdvanceFromSplashUseCase {

    private let sessionRepository: SessionRepository
    private let accountRepository: AccountRepository

    public init(
        sessionRepository: SessionRepository,
        accountRepository: AccountRepository
    ) {
        self.sessionRepository = sessionRepository
        self.accountRepository = accountRepository
    }

    @discardableResult
    public func execute() async -> AppPhase {
        await accountRepository.restore()

        guard accountRepository.isSignedIn else {
            // Account state is the gate — not persisted; re-checked each launch.
            return .accountLogin
        }

        let next: AppPhase = sessionRepository.faceIDLock ? .login : .home
        sessionRepository.savePhase(next)
        return next
    }
}

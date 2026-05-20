//
//  RestoreSessionUseCase.swift
//  UginsVault — Domain layer
//
//  Restores any persisted backend session at launch and reports whether the
//  user is signed in, so the root router can choose between the account-login
//  screen and the local Face ID gate.
//

import Foundation

@MainActor
public final class RestoreSessionUseCase {

    private let accountRepository: AccountRepository

    public init(accountRepository: AccountRepository) {
        self.accountRepository = accountRepository
    }

    /// - Returns: `true` when a valid session was restored.
    public func execute() async -> Bool {
        await accountRepository.restore()
        return accountRepository.isSignedIn
    }
}

//
//  SignOutAccountUseCase.swift
//  UginsVault — Domain layer
//
//  Clears the backend account session. Local app state (phase, Face ID lock)
//  is reset separately by the caller.
//

import Foundation

public final class SignOutAccountUseCase: Sendable {

    private let accountRepository: AccountRepository

    public init(accountRepository: AccountRepository) {
        self.accountRepository = accountRepository
    }

    public func execute() async {
        await accountRepository.signOut()
    }
}

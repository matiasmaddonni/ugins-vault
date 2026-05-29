//
//  SignInUseCase.swift
//  UginsVault — Domain layer
//
//  Signs the user into their backend account with email + password.
//

import Foundation

public final class SignInUseCase: Sendable {

    private let accountRepository: AccountRepository

    public init(accountRepository: AccountRepository) {
        self.accountRepository = accountRepository
    }

    /// - Throws: `AccountAuthError` when the credentials are rejected or the
    ///   server can't be reached.
    public func execute(email: String, password: String) async throws {
        try await accountRepository.signIn(email: email, password: password)
    }
}

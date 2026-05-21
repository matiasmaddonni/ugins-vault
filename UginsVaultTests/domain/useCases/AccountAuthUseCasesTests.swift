//
//  AccountAuthUseCasesTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("Account auth use cases")
@MainActor
struct AccountAuthUseCasesTests {

    @Test("SignInUseCase delegates to the repository")
    func signIn() async throws {
        let account = MockAccountRepository()
        let sut = SignInUseCase(accountRepository: account)

        try await sut.execute(email: "a@b.com", password: "pw")

        #expect(account.signInCallCount == 1)
        #expect(account.lastSignInPassword == "pw")
        #expect(account.isSignedIn)
    }

    @Test("SignInUseCase propagates errors")
    func signInError() async {
        let account = MockAccountRepository()
        account.stubbedSignInError = AccountAuthError.network
        let sut = SignInUseCase(accountRepository: account)

        await #expect(throws: AccountAuthError.network) {
            try await sut.execute(email: "a@b.com", password: "pw")
        }
    }

    @Test("SignOutAccountUseCase clears the session")
    func signOut() async {
        let account = MockAccountRepository()
        account.isSignedIn = true
        let sut = SignOutAccountUseCase(accountRepository: account)

        await sut.execute()

        #expect(account.signOutCallCount == 1)
        #expect(account.isSignedIn == false)
    }

}

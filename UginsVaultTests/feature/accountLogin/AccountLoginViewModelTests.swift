//
//  AccountLoginViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@Suite("AccountLoginViewModel")
@MainActor
struct AccountLoginViewModelTests {

    private func makeSUT(
        account: MockAccountRepository,
        onProceed: @escaping () -> Void = {}
    ) -> AccountLoginViewModel {
        AccountLoginViewModel(
            signInUseCase: SignInUseCase(accountRepository: account),
            onProceed: onProceed
        )
    }

    @Test("canSubmit requires non-empty email + password")
    func canSubmit() {
        let sut = makeSUT(account: MockAccountRepository())
        #expect(sut.canSubmit == false)

        sut.email = "a@b.com"
        #expect(sut.canSubmit == false)

        sut.password = "pw"
        #expect(sut.canSubmit == true)
    }

    @Test("submit() success → .success phase, trims email, fires onProceed")
    func submitSuccess() async {
        let account = MockAccountRepository()
        var proceeded = false
        let sut = makeSUT(account: account, onProceed: { proceeded = true })
        sut.email = "  user@example.com  "
        sut.password = "secret"

        await sut.submit()

        #expect(sut.phase == .success)
        #expect(proceeded)
        #expect(account.signInCallCount == 1)
        #expect(account.lastSignInEmail == "user@example.com")
    }

    @Test("submit() failure → .failure with reason, does not proceed")
    func submitFailure() async {
        let account = MockAccountRepository()
        account.stubbedSignInError = AccountAuthError.invalidCredentials
        var proceeded = false
        let sut = makeSUT(account: account, onProceed: { proceeded = true })
        sut.email = "user@example.com"
        sut.password = "wrong"

        await sut.submit()

        #expect(proceeded == false)
        if case .failure(let reason) = sut.phase {
            #expect(reason == AccountAuthError.invalidCredentials.errorDescription)
        } else {
            Issue.record("Expected .failure phase, got \(sut.phase)")
        }
    }

    @Test("submit() is a no-op when the form is incomplete")
    func submitNoopWhenInvalid() async {
        let account = MockAccountRepository()
        let sut = makeSUT(account: account)

        await sut.submit()

        #expect(account.signInCallCount == 0)
        #expect(sut.phase == .idle)
    }

    #if DEBUG
    @Test("skipForDev fires onProceed without signing in")
    func skipForDev() {
        let account = MockAccountRepository()
        var proceeded = false
        let sut = makeSUT(account: account, onProceed: { proceeded = true })

        sut.skipForDev()

        #expect(proceeded)
        #expect(account.signInCallCount == 0)
    }
    #endif
}

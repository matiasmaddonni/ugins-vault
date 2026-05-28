//
//  LoginViewModelTests.swift
//  UginsVaultTests — Presentation
//

import Testing
@testable import UginsVault

@Suite("LoginViewModel")
@MainActor
struct LoginViewModelTests {

    private func makeSUT(
        outcome: AuthOutcome,
        biometryAvailable: Bool = true,
        onAuthenticated: @escaping () -> Void = {}
    ) -> (LoginViewModel, MockAuthRepository, SessionStateStore) {
        let auth = MockAuthRepository()
        auth.stubbedAuthenticateOutcome = outcome
        auth.stubbedIsBiometryAvailable = biometryAvailable
        let session = SessionStateStore(storage: MockSessionStorage())
        let useCase = AuthenticateUseCase(authRepository: auth, sessionRepository: session)
        let vm = LoginViewModel(
            authenticateUseCase: useCase,
            isBiometryAvailable: biometryAvailable,
            onAuthenticated: onAuthenticated
        )
        return (vm, auth, session)
    }

    @Test("Idle is the starting phase")
    func idleAtStart() {
        let (sut, _, _) = makeSUT(outcome: .success)
        #expect(sut.phase == .idle)
    }

    @Test("Successful auth lands on .success and calls the callback")
    func successPath() async {
        var callbackCount = 0
        let (sut, _, session) = makeSUT(
            outcome: .success,
            onAuthenticated: { callbackCount += 1 }
        )

        await sut.authenticate()

        #expect(sut.phase == .success)
        #expect(callbackCount == 1)
        #expect(session.phase == .home)
    }

    @Test("Cancellation returns to .idle and doesn't call the callback")
    func cancelledPath() async {
        var callbackCount = 0
        let (sut, _, _) = makeSUT(
            outcome: .userCancelled,
            onAuthenticated: { callbackCount += 1 }
        )

        await sut.authenticate()

        #expect(sut.phase == .idle)
        #expect(callbackCount == 0)
    }

    @Test("Unavailable lands on .failure with a reason")
    func unavailablePath() async {
        let (sut, _, _) = makeSUT(outcome: .unavailable)

        await sut.authenticate()

        if case .failure = sut.phase {
            // ok
        } else {
            Issue.record("Expected .failure, got \(sut.phase)")
        }
    }

    @Test("Failed outcome propagates reason into phase")
    func failedPath() async {
        let (sut, _, _) = makeSUT(outcome: .failed(reason: "Try again"))

        await sut.authenticate()

        #expect(sut.phase == .failure(reason: "Try again"))
    }

    @Test("Re-entry while .scanning is ignored")
    func reentryIgnoredWhileBusy() async {
        let auth = MockAuthRepository()
        auth.stubbedAuthenticateOutcome = .success
        let session = SessionStateStore(storage: MockSessionStorage())
        let useCase = AuthenticateUseCase(authRepository: auth, sessionRepository: session)
        let sut = LoginViewModel(
            authenticateUseCase: useCase,
            isBiometryAvailable: true,
            onAuthenticated: {}
        )

        // First call kicks the auth off…
        let first = Task { await sut.authenticate() }
        // …re-entry while scanning should bail without incrementing repo count.
        await sut.authenticate()
        await first.value

        #expect(auth.authenticateCallCount == 1)
    }

    @Test("bypassAuthentication() calls the success callback directly")
    func bypassFiresCallback() {
        var callbackCount = 0
        let (sut, _, _) = makeSUT(
            outcome: .success,
            onAuthenticated: { callbackCount += 1 }
        )

        sut.bypassAuthentication()

        #expect(callbackCount == 1)
        // Bypass should NOT mutate phase nor persist session — that's the
        // distinction from real authentication.
        #expect(sut.phase == .idle)
    }
}

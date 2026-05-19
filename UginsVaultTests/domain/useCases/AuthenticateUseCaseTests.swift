//
//  AuthenticateUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("AuthenticateUseCase")
@MainActor
struct AuthenticateUseCaseTests {

    @Test("Success outcome persists phase = .home")
    func successPersistsHomePhase() async {
        let auth = MockAuthRepository()
        auth.stubbedAuthenticateOutcome = .success
        let session = MockSessionRepository()
        let sut = AuthenticateUseCase(authRepository: auth, sessionRepository: session)

        let outcome = await sut.execute(reason: "test")

        #expect(outcome == .success)
        #expect(session.savedPhase == .home)
        #expect(session.savePhaseCallCount == 1)
    }

    @Test("Cancellation does not touch session phase")
    func cancellationLeavesPhaseUntouched() async {
        let auth = MockAuthRepository()
        auth.stubbedAuthenticateOutcome = .userCancelled
        let session = MockSessionRepository()
        let sut = AuthenticateUseCase(authRepository: auth, sessionRepository: session)

        let outcome = await sut.execute(reason: "test")

        #expect(outcome == .userCancelled)
        #expect(session.savedPhase == nil)
        #expect(session.savePhaseCallCount == 0)
    }

    @Test("Unavailable does not touch session phase")
    func unavailableLeavesPhaseUntouched() async {
        let auth = MockAuthRepository()
        auth.stubbedAuthenticateOutcome = .unavailable
        let session = MockSessionRepository()
        let sut = AuthenticateUseCase(authRepository: auth, sessionRepository: session)

        let outcome = await sut.execute(reason: "test")

        #expect(outcome == .unavailable)
        #expect(session.savedPhase == nil)
    }

    @Test("Forwards reason verbatim to the repository")
    func forwardsReason() async {
        let auth = MockAuthRepository()
        let session = MockSessionRepository()
        let sut = AuthenticateUseCase(authRepository: auth, sessionRepository: session)

        _ = await sut.execute(reason: "Unlock your vault")

        #expect(auth.lastReason == "Unlock your vault")
        #expect(auth.authenticateCallCount == 1)
    }

    @Test("Failure outcome propagates reason and does not persist phase")
    func failurePropagates() async {
        let auth = MockAuthRepository()
        auth.stubbedAuthenticateOutcome = .failed(reason: "Sensor error")
        let session = MockSessionRepository()
        let sut = AuthenticateUseCase(authRepository: auth, sessionRepository: session)

        let outcome = await sut.execute(reason: "test")

        #expect(outcome == .failed(reason: "Sensor error"))
        #expect(session.savedPhase == nil)
    }
}

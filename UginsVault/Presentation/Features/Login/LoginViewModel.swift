//
//  LoginViewModel.swift
//  UginsVault — Presentation: Login
//
//  Owns the auth-flow state (idle → scanning → success / failure) and exposes
//  a single `authenticate()` intent. Calls back to the parent on success.
//

import Foundation
import Observation

@MainActor
@Observable
public final class LoginViewModel {

    // MARK: - Auth phase

    public enum AuthPhase: Equatable {
        case idle
        case scanning
        case success
        case failure(reason: String)

        public var isBusy: Bool {
            self == .scanning
        }
    }

    // MARK: - Observed state

    public private(set) var phase: AuthPhase = .idle
    public private(set) var isBiometryAvailable: Bool

    // MARK: - Dependencies

    @ObservationIgnored private let authenticateUseCase: AuthenticateUseCase
    @ObservationIgnored private let onAuthenticated: () -> Void

    // MARK: - Init

    public init(
        authenticateUseCase: AuthenticateUseCase,
        isBiometryAvailable: Bool,
        onAuthenticated: @escaping () -> Void
    ) {
        self.authenticateUseCase = authenticateUseCase
        self.isBiometryAvailable = isBiometryAvailable
        self.onAuthenticated = onAuthenticated
    }

    // MARK: - Intents

    /// Triggers a Face ID / passcode prompt.
    public func authenticate() async {
        guard !phase.isBusy else { return }
        phase = .scanning

        let outcome = await authenticateUseCase.execute(reason: "Unlock your vault")
        switch outcome {
        case .success:
            phase = .success
            try? await Task.sleep(for: .milliseconds(350))
            onAuthenticated()

        case .userCancelled:
            phase = .idle

        case .fallback:
            // PIN flow not in skeleton scope — drop back to idle.
            phase = .idle

        case .unavailable:
            phase = .failure(reason: "Biometry unavailable on this device")

        case .failed(let reason):
            phase = .failure(reason: reason)
        }
    }

    /// Dev shortcut — skips authentication entirely. Used by the simulator
    /// and non-bio builds. Real builds should hide the UI affordance.
    public func bypassAuthentication() {
        onAuthenticated()
    }
}

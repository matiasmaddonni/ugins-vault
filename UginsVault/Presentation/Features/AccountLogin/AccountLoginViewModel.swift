//
//  AccountLoginViewModel.swift
//  UginsVault — Presentation: AccountLogin
//
//  Owns the email/password sign-in form state and the single `submit()`
//  intent. Calls back to the parent on success so the root router can advance
//  to the local Face ID gate (or straight home when the lock is off).
//

import Foundation
import Observation

@MainActor
@Observable
public final class AccountLoginViewModel {

    // MARK: - Phase

    public enum Phase: Equatable {
        case idle
        case submitting
        case success
        case failure(reason: String)

        public var isBusy: Bool { self == .submitting }
    }

    // MARK: - Form state

    public var email: String = ""
    public var password: String = ""

    // MARK: - Observed state

    public private(set) var phase: Phase = .idle

    // MARK: - Dependencies

    @ObservationIgnored private let signInUseCase: SignInUseCase
    @ObservationIgnored private let onProceed: () -> Void

    // MARK: - Init

    public init(
        signInUseCase: SignInUseCase,
        onProceed: @escaping () -> Void
    ) {
        self.signInUseCase = signInUseCase
        self.onProceed = onProceed
    }

    // MARK: - Derived

    public var canSubmit: Bool {
        !trimmedEmail.isEmpty && !password.isEmpty && !phase.isBusy
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Intents

    /// Attempts an email/password sign-in. On success, fires `onProceed`.
    public func submit() async {
        guard canSubmit else { return }
        phase = .submitting

        do {
            try await signInUseCase.execute(email: trimmedEmail, password: password)
            phase = .success
            onProceed()
        } catch {
            let reason = (error as? AccountAuthError)?.errorDescription
                ?? error.localizedDescription
            phase = .failure(reason: reason)
        }
    }

    #if DEBUG
    /// Dev shortcut — enters the app with no backend session (local-only, no
    /// price calls). Compiled out of release builds.
    public func skipForDev() {
        onProceed()
    }
    #endif
}

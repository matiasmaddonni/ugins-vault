//
//  SplashViewModel.swift
//  UginsVault — Presentation: Splash
//
//  Drives the splash hold timer, then asks the parent (RootViewModel) to
//  transition to the next phase. No business logic beyond the timer.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SplashViewModel {

    // MARK: - Observed state

    /// Drives the entry animation. Flipped to `true` on first `start()` call.
    public private(set) var didAppear: Bool = false

    // MARK: - Configuration

    @ObservationIgnored public let holdDuration: Duration

    // MARK: - Dependencies

    @ObservationIgnored private let advanceFromSplashUseCase: AdvanceFromSplashUseCase
    @ObservationIgnored private let onAdvance: (AppPhase) -> Void

    @ObservationIgnored private var hasStarted: Bool = false

    // MARK: - Init

    public init(
        advanceFromSplashUseCase: AdvanceFromSplashUseCase,
        onAdvance: @escaping (AppPhase) -> Void,
        holdDuration: Duration = .milliseconds(1500)
    ) {
        self.advanceFromSplashUseCase = advanceFromSplashUseCase
        self.onAdvance = onAdvance
        self.holdDuration = holdDuration
    }

    // MARK: - Intents

    /// Starts the hold timer. Safe to call multiple times — only the first
    /// invocation triggers the advance.
    public func start() {
        guard !hasStarted else { return }
        hasStarted = true
        didAppear = true

        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.holdDuration)
            let next = self.advanceFromSplashUseCase.execute()
            self.onAdvance(next)
        }
    }
}

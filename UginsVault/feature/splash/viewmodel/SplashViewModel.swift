//
//  SplashViewModel.swift
//  UginsVault — Presentation: Splash
//
//  Drives the splash hold timer, then asks the parent (RootViewModel) to
//  transition to the next phase. No business logic beyond the timer.
//

import Foundation
import Combine

@MainActor
public final class SplashViewModel: ObservableObject {

    // MARK: - Published state

    /// Drives the entry animation. Flipped to `true` on first `start()` call.
    @Published public private(set) var didAppear: Bool = false

    // MARK: - Configuration

    public let holdDuration: Duration

    // MARK: - Dependencies

    private let advanceFromSplashUseCase: AdvanceFromSplashUseCase
    private let onAdvance: (AppPhase) -> Void

    private var hasStarted: Bool = false

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

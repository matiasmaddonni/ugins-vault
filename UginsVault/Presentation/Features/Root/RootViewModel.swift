//
//  RootViewModel.swift
//  UginsVault — Presentation: Root
//
//  Owns the top-level phase and exposes transition methods consumed by child
//  ViewModels via callbacks supplied at construction time.
//

import Foundation
import Observation

@MainActor
@Observable
public final class RootViewModel {

    // MARK: - Observed state

    public private(set) var phase: AppPhase

    // MARK: - Init

    /// Always begins at `.splash`. The splash advance re-evaluates the account
    /// + Face ID gates on every cold launch (so Face ID re-locks between runs),
    /// which is why there is no persisted-phase fast path here.
    public init() {
        self.phase = .splash
    }

    // MARK: - Intents

    public func transition(to phase: AppPhase) {
        guard self.phase != phase else { return }
        self.phase = phase
    }
}

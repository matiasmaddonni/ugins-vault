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

    // MARK: - Dependencies

    @ObservationIgnored private let getCurrentPhaseUseCase: GetCurrentPhaseUseCase

    // MARK: - Init

    public init(getCurrentPhaseUseCase: GetCurrentPhaseUseCase) {
        self.getCurrentPhaseUseCase = getCurrentPhaseUseCase
        self.phase = getCurrentPhaseUseCase.execute()
    }

    // MARK: - Intents

    public func transition(to phase: AppPhase) {
        guard self.phase != phase else { return }
        self.phase = phase
    }
}

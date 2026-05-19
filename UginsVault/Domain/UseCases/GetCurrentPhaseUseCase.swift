//
//  GetCurrentPhaseUseCase.swift
//  UginsVault — Domain layer
//
//  Reads the persisted phase. Used by RootViewModel at launch to decide which
//  screen to show first.
//

import Foundation

public final class GetCurrentPhaseUseCase: Sendable {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> AppPhase {
        sessionRepository.loadPhase()
    }
}

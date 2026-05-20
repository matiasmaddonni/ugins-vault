//
//  ManualARSRateUseCases.swift
//  UginsVault — Domain layer
//
//  Get + set the optional manual USD → ARS rate. When non-nil, the
//  FX layer skips the dolarapi blue feed and uses this value. Lets
//  the user pin a rate they bought at.
//

import Foundation

@MainActor
public final class GetManualARSRateUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Decimal? {
        sessionRepository.manualARSRate
    }
}

@MainActor
public final class SetManualARSRateUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    /// Pass a positive value to override; pass `nil` to fall back to
    /// the live blue-dollar feed.
    public func execute(_ rate: Decimal?) {
        if let rate, rate > 0 {
            sessionRepository.saveManualARSRate(rate)
        } else {
            sessionRepository.saveManualARSRate(nil)
        }
    }
}

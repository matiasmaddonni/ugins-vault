//
//  PreferredPriceSourceUseCases.swift
//  UginsVault — Domain layer
//
//  Get + set the user's preferred retail price marketplace. Used by
//  Card detail (which prices to show), the Dashboard real-data
//  producer (which prices to aggregate), and the Settings picker.
//

import Foundation

@MainActor
public final class GetPreferredPriceSourceUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> PriceSource {
        sessionRepository.preferredPriceSource
    }
}

@MainActor
public final class SetPreferredPriceSourceUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ source: PriceSource) {
        sessionRepository.savePreferredPriceSource(source)
    }
}

//
//  DashboardMoverThresholdUseCases.swift
//  UginsVault — Domain layer
//
//  Get + set the minimum 7-day USD delta a card has to hit before
//  qualifying for the Dashboard gainers / losers lists. Default $1.
//

import Foundation

@MainActor
public final class GetDashboardMoverThresholdUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Decimal {
        sessionRepository.dashboardMoverThreshold
    }
}

@MainActor
public final class SetDashboardMoverThresholdUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ threshold: Decimal) {
        let clamped = max(0, threshold)
        sessionRepository.saveDashboardMoverThreshold(clamped)
    }
}

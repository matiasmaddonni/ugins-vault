//
//  GetCurrencyUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetCurrencyUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Currency {
        sessionRepository.currency
    }
}

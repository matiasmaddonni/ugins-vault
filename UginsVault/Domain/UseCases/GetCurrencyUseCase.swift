//
//  GetCurrencyUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

public final class GetCurrencyUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Currency {
        sessionRepository.currency
    }
}

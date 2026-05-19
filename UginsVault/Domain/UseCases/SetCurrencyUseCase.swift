//
//  SetCurrencyUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetCurrencyUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ currency: Currency) {
        sessionRepository.saveCurrency(currency)
    }
}

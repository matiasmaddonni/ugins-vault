//
//  SetCurrencyUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetCurrencyUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ currency: Currency) {
        sessionRepository.saveCurrency(currency)
    }
}

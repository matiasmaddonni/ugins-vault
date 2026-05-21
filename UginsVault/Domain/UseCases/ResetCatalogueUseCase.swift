//
//  ResetCatalogueUseCase.swift
//  UginsVault — Domain layer
//
//  Wipes the local card catalogue. Used by Settings → Data → Clear catalogue.
//  No re-seed: the catalogue fills only from the cards the user adds / imports.
//

import Foundation

@MainActor
public final class ResetCatalogueUseCase {

    private let cardRepository: CardRepository

    public init(cardRepository: CardRepository) {
        self.cardRepository = cardRepository
    }

    public func execute() async throws {
        try await cardRepository.deleteAll()
    }
}

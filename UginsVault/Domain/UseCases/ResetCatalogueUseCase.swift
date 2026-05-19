//
//  ResetCatalogueUseCase.swift
//  UginsVault — Domain layer
//
//  Wipes the local card catalogue + re-seeds it from the upstream
//  catalogue source. Used by Settings → Data → Reset catalogue.
//

import Foundation

@MainActor
public final class ResetCatalogueUseCase {

    private let cardRepository: CardRepository
    private let seedCatalogue: SeedCatalogueUseCase

    public init(
        cardRepository: CardRepository,
        seedCatalogue: SeedCatalogueUseCase
    ) {
        self.cardRepository = cardRepository
        self.seedCatalogue = seedCatalogue
    }

    @discardableResult
    public func execute(
        seedQuery: String,
        maxPages: Int = 10,
        progress: ((SeedCatalogueUseCase.Progress) -> Void)? = nil
    ) async throws -> Int {
        try await cardRepository.deleteAll()
        return try await seedCatalogue.execute(
            query: seedQuery,
            maxPages: maxPages,
            progress: progress
        )
    }
}

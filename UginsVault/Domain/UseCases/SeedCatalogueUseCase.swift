//
//  SeedCatalogueUseCase.swift
//  UginsVault — Domain layer
//
//  Pulls cards from a `CardCatalogueSource` and persists them through a
//  `CardRepository`. v0.2 uses Scryfall's `/cards/search` paging for a
//  curated set; v0.3 will swap to the multi-hundred-MB bulk dump.
//

import Foundation

@MainActor
public final class SeedCatalogueUseCase {

    public struct Progress: Sendable {
        public let page: Int
        public let savedCount: Int
        public let isFinished: Bool
    }

    private let source: CardCatalogueSource
    private let repository: CardRepository

    public init(source: CardCatalogueSource, repository: CardRepository) {
        self.source = source
        self.repository = repository
    }

    /// Pages through the source until `hasMore` flips false or `maxPages`
    /// is reached. Persists each batch through the repository.
    /// - Parameters:
    ///   - query: Catalogue source query (Scryfall syntax in production).
    ///   - maxPages: Safety cap to avoid runaway loops.
    ///   - progress: Optional callback for UI hooks (splash spinner, etc.).
    /// - Returns: Total number of cards saved.
    @discardableResult
    public func execute(
        query: String,
        maxPages: Int = 10,
        progress: ((Progress) -> Void)? = nil
    ) async throws -> Int {

        var page = 1
        var savedTotal = 0

        while page <= maxPages {
            let result: CardCataloguePage
            do {
                result = try await source.fetchCards(query: query, page: page)
            } catch let error as ScryfallError {
                // A 404 on page > 1 means we paged past the end — that's
                // fine when the source doesn't advertise `has_more = false`
                // on the last page.
                if case .apiError(_, let envelope) = error,
                   envelope.code == "not_found",
                   page > 1 {
                    break
                }
                throw error
            }

            if !result.cards.isEmpty {
                try await repository.save(result.cards)
                savedTotal += result.cards.count
            }

            progress?(Progress(
                page: page,
                savedCount: savedTotal,
                isFinished: !result.hasMore
            ))

            if !result.hasMore { break }
            page += 1
        }

        return savedTotal
    }
}

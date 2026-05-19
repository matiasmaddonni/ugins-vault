//
//  CardCatalogueSource.swift
//  UginsVault — Domain layer
//
//  Abstract source of card data. Domain use cases (e.g. seeding the
//  catalogue) talk to this protocol; the Data layer ships a
//  Scryfall-backed implementation in `ScryfallCardCatalogueSource`.
//

import Foundation

public protocol CardCatalogueSource: Sendable {

    /// Fetches one paged result from the upstream catalogue.
    /// - Parameters:
    ///   - query: A free-form search string. The concrete implementation
    ///     decides how to translate it (Scryfall syntax, MTGJson keys, …).
    ///   - page: 1-indexed page number.
    /// - Returns: A page of `Card` plus a flag indicating whether more
    ///   pages exist.
    func fetchCards(query: String, page: Int) async throws -> CardCataloguePage
}

public struct CardCataloguePage: Sendable {

    public let cards: [Card]
    public let hasMore: Bool

    public init(cards: [Card], hasMore: Bool) {
        self.cards = cards
        self.hasMore = hasMore
    }
}

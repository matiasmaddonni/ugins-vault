//
//  ScryfallCardCatalogueSource.swift
//  UginsVault — Data layer / Scryfall
//
//  Implements the Domain `CardCatalogueSource` by querying Scryfall's
//  `/cards/search` endpoint and mapping DTOs to Domain `Card`s.
//

import Foundation

public final class ScryfallCardCatalogueSource: CardCatalogueSource {

    private let client: any ScryfallClientProtocol

    public init(client: any ScryfallClientProtocol) {
        self.client = client
    }

    public func fetchCards(query: String, page: Int) async throws -> CardCataloguePage {
        let list = try await client.searchCards(query: query, page: page)
        let cards = list.data.compactMap(Card.init(from:))
        return CardCataloguePage(cards: cards, hasMore: list.hasMore)
    }
}

//
//  MockScryfallClient.swift
//  UginsVaultTests — mocks
//

import Foundation
@testable import UginsVault

/// Minimal `ScryfallClientProtocol` actor for tests. Only `card(id:)` is
/// meaningful; the others throw.
actor MockScryfallClient: ScryfallClientProtocol {

    private let cardByID: ScryfallCard?
    private let shouldThrow: Bool
    private let collectionCards: [ScryfallCard]
    private let searchResults: [ScryfallCard]
    private(set) var requestedIDs: [UUID] = []

    init(
        card: ScryfallCard? = nil,
        shouldThrow: Bool = false,
        collectionCards: [ScryfallCard] = [],
        searchResults: [ScryfallCard] = []
    ) {
        self.cardByID = card
        self.shouldThrow = shouldThrow
        self.collectionCards = collectionCards
        self.searchResults = searchResults
    }

    func card(id: UUID) async throws -> ScryfallCard {
        requestedIDs.append(id)
        guard !shouldThrow, let cardByID else {
            throw ScryfallError.transport(underlying: URLError(.notConnectedToInternet))
        }
        return cardByID
    }

    func card(named: String, set: String?, fuzzy: Bool) async throws -> ScryfallCard {
        throw ScryfallError.transport(underlying: URLError(.unsupportedURL))
    }

    func searchCards(query: String, page: Int) async throws -> ScryfallList<ScryfallCard> {
        if shouldThrow { throw ScryfallError.transport(underlying: URLError(.notConnectedToInternet)) }
        return ScryfallList(data: searchResults)
    }

    func collection(identifiers: [ScryfallCardIdentifier]) async throws -> [ScryfallCard] {
        if shouldThrow { throw ScryfallError.transport(underlying: URLError(.notConnectedToInternet)) }
        return collectionCards
    }
}

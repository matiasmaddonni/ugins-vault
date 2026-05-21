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
    private(set) var requestedIDs: [UUID] = []

    init(card: ScryfallCard? = nil, shouldThrow: Bool = false) {
        self.cardByID = card
        self.shouldThrow = shouldThrow
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
        throw ScryfallError.transport(underlying: URLError(.unsupportedURL))
    }
}

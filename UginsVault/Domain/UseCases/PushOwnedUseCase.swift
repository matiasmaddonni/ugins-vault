//
//  PushOwnedUseCase.swift
//  UginsVault — Domain layer
//
//  Sends the user's full collection (Scryfall ids + summed quantities) to the
//  backend so its ingest prices those cards. Quantities are summed across every
//  stack a printing appears in.
//

import Foundation

@MainActor
public final class PushOwnedUseCase {

    private let collectionItemRepository: CollectionItemRepository
    private let remoteOwnedSync: RemoteOwnedSync

    public init(
        collectionItemRepository: CollectionItemRepository,
        remoteOwnedSync: RemoteOwnedSync
    ) {
        self.collectionItemRepository = collectionItemRepository
        self.remoteOwnedSync = remoteOwnedSync
    }

    /// - Returns: the number of distinct printings pushed.
    @discardableResult
    public func execute() async throws -> Int {
        let items = try await collectionItemRepository.allItems()

        var quantityByCard: [UUID: Int] = [:]
        for item in items {
            quantityByCard[item.cardID, default: 0] += item.quantity
        }

        let cards = quantityByCard.map { OwnedCardCount(cardID: $0.key, quantity: $0.value) }
        try await remoteOwnedSync.push(cards)
        return cards.count
    }
}

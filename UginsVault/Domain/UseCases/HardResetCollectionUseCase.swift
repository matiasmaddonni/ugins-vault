//
//  HardResetCollectionUseCase.swift
//  UginsVault — Domain layer
//
//  DEBUG "start clean" reset. Unlike `ResetCatalogueUseCase` (which only
//  drops the local card-metadata cache), this wipes the WHOLE collection on
//  both sides so the next launch's restore can't repopulate it:
//
//    1. Backend collection — full PUT of an empty collection. Done FIRST: if
//       it fails (offline / signed out) we abort before touching local state,
//       so the user never ends up with a local wipe that the next restore
//       immediately undoes.
//    2. Local cache — items, stacks, and the card catalogue.
//
//  NOTE on prices: the backend `prices` table is GLOBAL (keyed by Scryfall
//  card id, shared across users), not per-user, so it is intentionally left
//  intact — it can't be wiped from the app and re-adding a card simply reuses
//  the already-ingested price. Per-user price *status* derives from the owned
//  set, so it empties automatically once the collection is gone.
//

import Foundation

public final class HardResetCollectionUseCase: Sendable {

    private let remote: RemoteCollectionStore
    private let itemRepository: CollectionItemRepository
    private let stackRepository: StackRepository
    private let cardRepository: CardRepository

    public init(
        remote: RemoteCollectionStore,
        itemRepository: CollectionItemRepository,
        stackRepository: StackRepository,
        cardRepository: CardRepository
    ) {
        self.remote = remote
        self.itemRepository = itemRepository
        self.stackRepository = stackRepository
        self.cardRepository = cardRepository
    }

    /// Wipes the backend collection, then the local cache. Throws (without
    /// touching local state) if the backend wipe fails.
    public func execute() async throws {
        try await remote.replaceAll(stacks: [], items: [])
        try await itemRepository.deleteAll()
        try await stackRepository.deleteAll()
        try await cardRepository.deleteAll()
    }
}

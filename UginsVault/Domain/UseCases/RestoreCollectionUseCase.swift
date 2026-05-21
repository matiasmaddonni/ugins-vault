//
//  RestoreCollectionUseCase.swift
//  UginsVault — Domain layer
//
//  Restores the local collection cache from the backend (the source of truth)
//  on launch / fresh install: GET the full collection, then mirror it into the
//  local stack + item stores. Card metadata (name / art / set) lives only on
//  Scryfall, so any printing not already cached is hydrated by id.
//
//  IMPORTANT: this writes to the *base* repositories — NOT the sync-decorated
//  ones — so restoring the server's truth doesn't echo straight back as a wave
//  of upserts.
//

import Foundation

@MainActor
public final class RestoreCollectionUseCase {

    // MARK: - Dependencies

    private let remote: RemoteCollectionStore
    private let stackRepository: StackRepository
    private let itemRepository: CollectionItemRepository
    private let cardRepository: CardRepository
    private let scryfallClient: any ScryfallClientProtocol

    public init(
        remote: RemoteCollectionStore,
        stackRepository: StackRepository,
        itemRepository: CollectionItemRepository,
        cardRepository: CardRepository,
        scryfallClient: any ScryfallClientProtocol
    ) {
        self.remote = remote
        self.stackRepository = stackRepository
        self.itemRepository = itemRepository
        self.cardRepository = cardRepository
        self.scryfallClient = scryfallClient
    }

    // MARK: - Execute

    /// Pulls the authoritative collection and mirrors it into the local cache.
    /// - Returns: the fetched collection (for callers that want the counts).
    @discardableResult
    public func execute() async throws -> RemoteCollection {
        let collection = try await remote.fetch()
        await hydrateMissingCards(Set(collection.items.map(\.cardID)))
        try await replaceLocal(with: collection)
        return collection
    }

    // MARK: - Helpers

    /// Wipes the local cache and re-inserts the server's stacks + items. Stacks
    /// first so items always have a parent to reference.
    private func replaceLocal(with collection: RemoteCollection) async throws {
        try await itemRepository.deleteAll()
        try await stackRepository.deleteAll()
        for stack in collection.stacks { try await stackRepository.save(stack) }
        for item in collection.items { try await itemRepository.save(item) }
    }

    /// Fetches + caches Scryfall data for any printing we don't have yet.
    /// Best-effort: a single Scryfall miss never fails the restore.
    private func hydrateMissingCards(_ ids: Set<UUID>) async {
        for id in ids {
            if (try? await cardRepository.card(id: id)) != nil { continue }
            guard let dto = try? await scryfallClient.card(id: id),
                  let card = Card(from: dto) else { continue }
            try? await cardRepository.save([card])
        }
    }
}

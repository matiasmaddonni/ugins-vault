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

public final class RestoreCollectionUseCase: Sendable {

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
        // Mirror stacks + items first so the UI has rows immediately; card
        // art/names are hydrated right after (batched, so it's quick).
        try await replaceLocal(with: collection)
        await hydrateMissingCards(Set(collection.items.map(\.cardID)))
        return collection
    }

    // MARK: - Helpers

    /// Wipes the local cache and re-inserts the server's stacks + items. Stacks
    /// first so items always have a parent to reference.
    private func replaceLocal(with collection: RemoteCollection) async throws {
        try await itemRepository.deleteAll()
        try await stackRepository.deleteAll()
        for stack in collection.stacks { try await stackRepository.save(stack) }
        // ONE batched write for all items — a save per item floods the main
        // actor and freezes the app during a fresh-install restore.
        try await itemRepository.save(collection.items)
    }

    /// Fetches + caches Scryfall data for any printing we don't have yet,
    /// BATCHED via `/cards/collection` (75 ids/request) instead of one call
    /// per card. Best-effort: a failed chunk never fails the restore.
    private func hydrateMissingCards(_ ids: Set<UUID>) async {
        var missing: [UUID] = []
        for id in ids where (try? await cardRepository.card(id: id)) == nil {
            missing.append(id)
        }
        guard !missing.isEmpty else { return }

        for chunk in missing.chunked(into: 75) {
            let identifiers = chunk.map { ScryfallCardIdentifier(id: $0) }
            guard let dtos = try? await scryfallClient.collection(identifiers: identifiers) else { continue }
            let cards = dtos.compactMap(Card.init(from:))
            try? await cardRepository.save(cards)
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

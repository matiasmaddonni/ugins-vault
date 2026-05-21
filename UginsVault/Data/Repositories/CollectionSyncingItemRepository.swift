//
//  CollectionSyncingItemRepository.swift
//  UginsVault — Data layer
//
//  Decorates a `CollectionItemRepository` so every local write also pushes a
//  debounced incremental change to the backend (the source of truth):
//    • save   → POST /v1/collection/items   (upsert by id)
//    • delete → DELETE /v1/collection/items (by id)
//  A burst of writes (e.g. a deck import) coalesces into one batch. Pushes are
//  best-effort: they no-op / throw-and-swallow when signed out or offline; the
//  next launch's restore reconciles.
//
//  `deleteAll(in:)` is local-only — deleting a Stack cascades its items on the
//  backend (DELETE /v1/collection/stacks). `deleteAll()` is local-only too:
//  full wipes come from restore (which writes the *base* repo) or a hard reset
//  (a full PUT), never an implicit fan-out of deletes.
//

import Foundation
import Observation

@MainActor
@Observable
public final class CollectionSyncingItemRepository: CollectionItemRepository {

    @ObservationIgnored private let wrapped: CollectionItemRepository
    @ObservationIgnored private let remote: RemoteCollectionStore
    @ObservationIgnored private let debounce: Duration

    @ObservationIgnored private var pendingUpsertIDs: Set<UUID> = []
    @ObservationIgnored private var pendingDeleteIDs: Set<UUID> = []
    @ObservationIgnored private var flushTask: Task<Void, Never>?

    public init(
        wrapped: CollectionItemRepository,
        remote: RemoteCollectionStore,
        debounce: Duration = .seconds(2)
    ) {
        self.wrapped = wrapped
        self.remote = remote
        self.debounce = debounce
    }

    public var isWriting: Bool { wrapped.isWriting }

    // MARK: - Reads (delegate)

    public func items(in stackID: UUID) async throws -> [CollectionItem] {
        try await wrapped.items(in: stackID)
    }

    public func cardCount(in stackID: UUID) async throws -> Int {
        try await wrapped.cardCount(in: stackID)
    }

    public func uniqueCount(in stackID: UUID) async throws -> Int {
        try await wrapped.uniqueCount(in: stackID)
    }

    public func item(id: UUID) async throws -> CollectionItem? {
        try await wrapped.item(id: id)
    }

    public func allItems() async throws -> [CollectionItem] {
        try await wrapped.allItems()
    }

    // MARK: - Writes (delegate + schedule push)

    public func save(_ item: CollectionItem) async throws {
        try await wrapped.save(item)
        pendingDeleteIDs.remove(item.id)
        pendingUpsertIDs.insert(item.id)
        scheduleFlush()
    }

    public func save(_ items: [CollectionItem]) async throws {
        try await wrapped.save(items)
        for item in items {
            pendingDeleteIDs.remove(item.id)
            pendingUpsertIDs.insert(item.id)
        }
        scheduleFlush()
    }

    public func delete(id: UUID) async throws {
        try await wrapped.delete(id: id)
        pendingUpsertIDs.remove(id)
        pendingDeleteIDs.insert(id)
        scheduleFlush()
    }

    public func deleteAll(in stackID: UUID) async throws {
        try await wrapped.deleteAll(in: stackID)   // stack delete cascades on the backend
    }

    public func deleteAll() async throws {
        try await wrapped.deleteAll()               // local-only by design
    }

    // MARK: - Debounced push

    private func scheduleFlush() {
        flushTask?.cancel()
        flushTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.debounce)
            guard !Task.isCancelled else { return }
            await self.flush()
        }
    }

    /// Sends the coalesced batch. Upserts re-read the *current* row so the
    /// latest quantity/finish wins; a delete supersedes a pending upsert.
    private func flush() async {
        let upsertIDs = pendingUpsertIDs
        let deleteIDs = pendingDeleteIDs
        pendingUpsertIDs = []
        pendingDeleteIDs = []

        var items: [CollectionItem] = []
        for id in upsertIDs {
            if let item = try? await wrapped.item(id: id) { items.append(item) }
        }
        try? await remote.upsertItems(items)
        try? await remote.deleteItems(ids: Array(deleteIDs))
    }
}

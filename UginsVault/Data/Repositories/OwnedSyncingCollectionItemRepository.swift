//
//  OwnedSyncingCollectionItemRepository.swift
//  UginsVault — Data layer
//
//  Decorates a `CollectionItemRepository` so every write (add / remove / stack
//  delete / reset) schedules a debounced push of the owned list to the backend
//  (`PUT /v1/owned`), keeping the server-side owned-union current between price
//  syncs. The push is best-effort: it no-ops when signed out.
//
//  Reads delegate straight through. `isWriting` forwarding is non-observable,
//  which is fine — nothing observes it reactively.
//

import Foundation
import Observation

@MainActor
@Observable
public final class OwnedSyncingCollectionItemRepository: CollectionItemRepository {

    @ObservationIgnored private let wrapped: CollectionItemRepository
    @ObservationIgnored private let pushOwned: PushOwnedUseCase
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var pendingPush: Task<Void, Never>?

    public init(
        wrapped: CollectionItemRepository,
        pushOwned: PushOwnedUseCase,
        debounce: Duration = .seconds(2)
    ) {
        self.wrapped = wrapped
        self.pushOwned = pushOwned
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
        scheduleOwnedPush()
    }

    public func delete(id: UUID) async throws {
        try await wrapped.delete(id: id)
        scheduleOwnedPush()
    }

    public func deleteAll(in stackID: UUID) async throws {
        try await wrapped.deleteAll(in: stackID)
        scheduleOwnedPush()
    }

    public func deleteAll() async throws {
        try await wrapped.deleteAll()
        scheduleOwnedPush()
    }

    // MARK: - Debounced push

    /// Coalesces a burst of writes (e.g. a deck import) into a single push.
    private func scheduleOwnedPush() {
        pendingPush?.cancel()
        pendingPush = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.debounce)
            guard !Task.isCancelled else { return }
            _ = try? await self.pushOwned.execute()
        }
    }
}

//
//  RemoteCollectionStore.swift
//  UginsVault — Domain layer
//
//  The backend is the SOURCE OF TRUTH for the user's collection; the on-device
//  SwiftData store is a cache. This seam is how the app reads the authoritative
//  collection (restore on launch) and pushes local edits back. The concrete
//  implementation (`BackendCollectionStore`) lives in Data.
//
//  Edits are incremental + keyed by the app-owned `id` UUID (stable per row):
//  `upsert*` = insert-or-update by id, `delete*` = remove by id. `replaceAll`
//  is the full PUT — first import / hard reset only.
//

import Foundation

/// The authoritative collection as returned by the backend.
public struct RemoteCollection: Sendable, Equatable {
    public let stacks: [Stack]
    public let items: [CollectionItem]

    public init(stacks: [Stack], items: [CollectionItem]) {
        self.stacks = stacks
        self.items = items
    }
}

public protocol RemoteCollectionStore: Sendable {

    /// Full collection — used to restore the local cache on launch.
    func fetch() async throws -> RemoteCollection

    // MARK: - Incremental edits (normal path)

    func upsertItems(_ items: [CollectionItem]) async throws
    func deleteItems(ids: [UUID]) async throws
    func upsertStacks(_ stacks: [Stack]) async throws
    func deleteStacks(ids: [UUID]) async throws

    // MARK: - Full replace (first import / hard reset only)

    func replaceAll(stacks: [Stack], items: [CollectionItem]) async throws
}

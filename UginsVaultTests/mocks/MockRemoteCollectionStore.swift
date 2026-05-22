//
//  MockRemoteCollectionStore.swift
//  UginsVaultTests — mocks
//

import Foundation
@testable import UginsVault

/// Controllable `RemoteCollectionStore` that records every call.
final class MockRemoteCollectionStore: RemoteCollectionStore, @unchecked Sendable {

    var fetchResult: RemoteCollection = RemoteCollection(stacks: [], items: [])
    var fetchError: Error?
    var replaceError: Error?

    private(set) var upsertedItems: [[CollectionItem]] = []
    private(set) var deletedItemIDs: [[UUID]] = []
    private(set) var upsertedStacks: [[Stack]] = []
    private(set) var deletedStackIDs: [[UUID]] = []
    private(set) var replaced: (stacks: [Stack], items: [CollectionItem])?

    func fetch() async throws -> RemoteCollection {
        if let fetchError { throw fetchError }
        return fetchResult
    }

    func upsertItems(_ items: [CollectionItem]) async throws { upsertedItems.append(items) }
    func deleteItems(ids: [UUID]) async throws { deletedItemIDs.append(ids) }
    func upsertStacks(_ stacks: [Stack]) async throws { upsertedStacks.append(stacks) }
    func deleteStacks(ids: [UUID]) async throws { deletedStackIDs.append(ids) }
    func replaceAll(stacks: [Stack], items: [CollectionItem]) async throws {
        if let replaceError { throw replaceError }
        replaced = (stacks, items)
    }

    // MARK: - Flattened helpers
    var allUpsertedItemIDs: [UUID] { upsertedItems.flatMap { $0 }.map(\.id) }
    var allDeletedItemIDs: [UUID] { deletedItemIDs.flatMap { $0 } }
    var allUpsertedStackIDs: [UUID] { upsertedStacks.flatMap { $0 }.map(\.id) }
    var allDeletedStackIDs: [UUID] { deletedStackIDs.flatMap { $0 } }
}

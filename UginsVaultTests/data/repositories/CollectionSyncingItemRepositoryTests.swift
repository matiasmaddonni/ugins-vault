//
//  CollectionSyncingItemRepositoryTests.swift
//  UginsVaultTests — Data
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("CollectionSyncingItemRepository")
@MainActor
struct CollectionSyncingItemRepositoryTests {

    private func makeSUT() throws -> (
        CollectionSyncingItemRepository,
        SwiftDataCollectionItemRepository,
        MockRemoteCollectionStore
    ) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCollectionItem.self, configurations: config)
        let base = SwiftDataCollectionItemRepository(modelContainer: container)
        let remote = MockRemoteCollectionStore()
        let sut = CollectionSyncingItemRepository(wrapped: base, remote: remote, debounce: .milliseconds(20))
        return (sut, base, remote)
    }

    @Test("reads delegate to the wrapped repo")
    func readsDelegate() async throws {
        let (sut, base, _) = try makeSUT()
        let stackID = UUID()
        let item = CollectionItem(cardID: UUID(), stackID: stackID, quantity: 3)
        try await base.save(item)

        #expect(try await sut.items(in: stackID).count == 1)
        #expect(try await sut.cardCount(in: stackID) == 3)
        #expect(try await sut.uniqueCount(in: stackID) == 1)
        #expect(try await sut.item(id: item.id)?.id == item.id)
        #expect(try await sut.allItems().count == 1)
    }

    @Test("save persists locally + pushes a debounced upsert")
    func savePushesUpsert() async throws {
        let (sut, base, remote) = try makeSUT()
        let item = CollectionItem(cardID: UUID(), stackID: UUID(), quantity: 2)

        try await sut.save(item)
        try await Task.sleep(for: .milliseconds(150))

        #expect(try await base.item(id: item.id)?.quantity == 2)
        #expect(remote.allUpsertedItemIDs.contains(item.id))
    }

    @Test("batch save persists all rows + pushes one upsert batch")
    func batchSavePushes() async throws {
        let (sut, base, remote) = try makeSUT()
        let items = [
            CollectionItem(cardID: UUID(), stackID: UUID()),
            CollectionItem(cardID: UUID(), stackID: UUID())
        ]

        try await sut.save(items)
        try await Task.sleep(for: .milliseconds(150))

        #expect(try await base.allItems().count == 2)
        #expect(items.allSatisfy { remote.allUpsertedItemIDs.contains($0.id) })
    }

    @Test("delete removes locally + pushes a delete")
    func deletePushesDelete() async throws {
        let (sut, _, remote) = try makeSUT()
        let item = CollectionItem(cardID: UUID(), stackID: UUID())
        try await sut.save(item)
        try await Task.sleep(for: .milliseconds(150))

        try await sut.delete(id: item.id)
        try await Task.sleep(for: .milliseconds(150))

        #expect(remote.allDeletedItemIDs.contains(item.id))
    }

    @Test("deleteAll(in:) is local-only — the stack delete cascades server-side")
    func deleteAllInStackDoesNotPush() async throws {
        let (sut, _, remote) = try makeSUT()

        try await sut.deleteAll(in: UUID())
        try await Task.sleep(for: .milliseconds(120))

        #expect(remote.upsertedItems.isEmpty)
        #expect(remote.deletedItemIDs.isEmpty)
    }

    @Test("deleteAll() is local-only")
    func deleteAllDoesNotPush() async throws {
        let (sut, _, remote) = try makeSUT()

        try await sut.deleteAll()
        try await Task.sleep(for: .milliseconds(120))

        #expect(remote.upsertedItems.isEmpty)
        #expect(remote.deletedItemIDs.isEmpty)
    }
}

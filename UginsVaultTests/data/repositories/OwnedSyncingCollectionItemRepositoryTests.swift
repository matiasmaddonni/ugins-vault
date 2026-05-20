//
//  OwnedSyncingCollectionItemRepositoryTests.swift
//  UginsVaultTests — Data
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("OwnedSyncingCollectionItemRepository")
@MainActor
struct OwnedSyncingCollectionItemRepositoryTests {

    final class CountingOwnedSync: RemoteOwnedSync, @unchecked Sendable {
        private(set) var pushCount = 0
        func push(_ cards: [OwnedCardCount]) async throws { pushCount += 1 }
    }

    private func makeSUT(
        sync: CountingOwnedSync,
        debounce: Duration = .milliseconds(100)
    ) throws -> (OwnedSyncingCollectionItemRepository, SwiftDataCollectionItemRepository) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCollectionItem.self, configurations: config)
        let base = SwiftDataCollectionItemRepository(modelContainer: container)
        let push = PushOwnedUseCase(collectionItemRepository: base, remoteOwnedSync: sync)
        let sut = OwnedSyncingCollectionItemRepository(wrapped: base, pushOwned: push, debounce: debounce)
        return (sut, base)
    }

    @Test("save schedules a debounced owned push")
    func savePushes() async throws {
        let sync = CountingOwnedSync()
        let (sut, _) = try makeSUT(sync: sync)

        try await sut.save(CollectionItem(cardID: UUID(), stackID: UUID()))
        try await Task.sleep(for: .milliseconds(300))

        #expect(sync.pushCount == 1)
    }

    @Test("a burst of writes coalesces into a single push")
    func burstCoalesces() async throws {
        let sync = CountingOwnedSync()
        let (sut, _) = try makeSUT(sync: sync)

        for _ in 0..<5 {
            try await sut.save(CollectionItem(cardID: UUID(), stackID: UUID()))
        }
        try await Task.sleep(for: .milliseconds(300))

        #expect(sync.pushCount == 1)
    }

    @Test("delete schedules a push")
    func deletePushes() async throws {
        let sync = CountingOwnedSync()
        let (sut, base) = try makeSUT(sync: sync)
        let item = CollectionItem(cardID: UUID(), stackID: UUID())
        try await base.save(item) // seed via base — no push

        try await sut.delete(id: item.id)
        try await Task.sleep(for: .milliseconds(300))

        #expect(sync.pushCount == 1)
    }

    @Test("reads delegate to the wrapped repo")
    func readsDelegate() async throws {
        let sync = CountingOwnedSync()
        let (sut, base) = try makeSUT(sync: sync)
        let stackID = UUID()
        try await base.save(CollectionItem(cardID: UUID(), stackID: stackID))

        let items = try await sut.items(in: stackID)

        #expect(items.count == 1)
        #expect(sync.pushCount == 0) // reads don't push
    }
}

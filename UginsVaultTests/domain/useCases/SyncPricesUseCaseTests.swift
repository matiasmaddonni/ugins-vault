//
//  SyncPricesUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SyncPricesUseCase")
@MainActor
struct SyncPricesUseCaseTests {

    @MainActor
    final class CaptureSource: PriceCatalogueSource {
        var snapshots: [PriceSnapshot] = []
        var error: Error?
        private(set) var received: Set<UUID>?
        func fetchSnapshots(ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot] {
            received = ownedCardIDs
            if let error { throw error }
            return snapshots
        }
    }

    final class CapturingOwnedSync: RemoteOwnedSync, @unchecked Sendable {
        private(set) var pushed = false
        func push(_ cards: [OwnedCardCount]) async throws { pushed = true }
    }

    private func makeItemRepo() throws -> SwiftDataCollectionItemRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCollectionItem.self, configurations: config)
        return SwiftDataCollectionItemRepository(modelContainer: container)
    }

    private func makeSUT(
        price: MockPriceRepository,
        items: SwiftDataCollectionItemRepository,
        backend: CaptureSource,
        sync: RemoteOwnedSync = CapturingOwnedSync()
    ) -> SyncPricesUseCase {
        SyncPricesUseCase(
            priceRepository: price,
            collectionItemRepository: items,
            backendSource: backend,
            pushOwned: PushOwnedUseCase(collectionItemRepository: items, remoteOwnedSync: sync)
        )
    }

    @Test("no owned cards → throws noOwnedCards")
    func emptyThrows() async throws {
        let items = try makeItemRepo()
        let sut = makeSUT(price: MockPriceRepository(), items: items, backend: CaptureSource())

        await #expect(throws: SyncPricesUseCase.SyncError.self) {
            try await sut.execute()
        }
    }

    @Test("backend prices are pushed, fetched, stored, and the clock stamped")
    func backendStores() async throws {
        let items = try makeItemRepo()
        let card = UUID()
        try await items.save(CollectionItem(cardID: card, stackID: UUID()))

        let price = MockPriceRepository()
        let backend = CaptureSource()
        backend.snapshots = [PriceSnapshot(cardID: card, source: .tcgplayer, date: Date(), currency: .usd, retail: 5)]
        let owned = CapturingOwnedSync()
        let sut = makeSUT(price: price, items: items, backend: backend, sync: owned)

        let count = try await sut.execute()

        #expect(count == 1)
        #expect(owned.pushed)
        #expect(backend.received == [card])
        #expect(price.upserts.count == 1)
        #expect(price.upserts.first?.count == 1)
        #expect(price.lastSyncedAt != nil)
    }

    @Test("backend failure → SyncError, no timestamp")
    func backendThrows() async throws {
        struct Boom: Error {}
        let items = try makeItemRepo()
        try await items.save(CollectionItem(cardID: UUID(), stackID: UUID()))

        let price = MockPriceRepository()
        let backend = CaptureSource()
        backend.error = Boom()
        let sut = makeSUT(price: price, items: items, backend: backend)

        await #expect(throws: SyncPricesUseCase.SyncError.self) {
            try await sut.execute()
        }
        #expect(price.lastSyncedAt == nil)
    }
}

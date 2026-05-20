//
//  PriceSyncViewModelTests.swift
//  UginsVaultTests
//

import Foundation
import Observation
import SwiftData
import Testing
@testable import UginsVault

@Suite("PriceSyncViewModel")
@MainActor
struct PriceSyncViewModelTests {

    @MainActor
    final class StubReachability: NetworkReachability {
        var isOnWiFi: Bool = true
    }

    @MainActor
    final class StubSource: PriceCatalogueSource {
        var queued: Result<[PriceSnapshot], Error> = .success([])
        var calls = 0
        func fetchSnapshots(ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot] {
            calls += 1
            switch queued {
            case .success(let array): return array
            case .failure(let err): throw err
            }
        }
    }

    struct NoopOwnedSync: RemoteOwnedSync {
        func push(_ cards: [OwnedCardCount]) async throws {}
    }

    final class InMemoryStorage: SessionStorageDataSource, @unchecked Sendable {
        private var bag: [String: String] = [:]
        func string(forKey key: String) -> String? { bag[key] }
        func set(_ value: String?, forKey key: String) {
            if let value { bag[key] = value } else { bag.removeValue(forKey: key) }
        }
    }

    /// Returns an empty catalogue page so the seed step doesn't hit Scryfall.
    final class NoopCatalogueSource: CardCatalogueSource, @unchecked Sendable {
        func fetchCards(query: String, page: Int) async throws -> CardCataloguePage {
            CardCataloguePage(cards: [], hasMore: false)
        }
    }

    /// Spins up a full real-stack VM with an in-memory SwiftData container and
    /// a controllable backend source. The MTGJSON fallback is a stub returning
    /// nothing so behaviour stays deterministic.
    private func makeSUT() throws -> (
        PriceSyncViewModel,
        SwiftDataCollectionItemRepository,
        SwiftDataPriceRepository,
        StubSource,
        StubReachability
    ) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self,
            SwiftDataPriceSnapshot.self,
            SwiftDataCollectionItem.self,
            SwiftDataWishlistItem.self,
            configurations: config
        )
        let cardRepo = SwiftDataCardRepository(modelContainer: container)
        let itemRepo = SwiftDataCollectionItemRepository(modelContainer: container)
        let priceRepo = SwiftDataPriceRepository(
            modelContainer: container,
            lastSyncStorage: InMemoryStorage()
        )
        let backend = StubSource()
        let reach = StubReachability()
        let useCase = SyncPricesUseCase(
            priceRepository: priceRepo,
            collectionItemRepository: itemRepo,
            backendSource: backend,
            pushOwned: PushOwnedUseCase(
                collectionItemRepository: itemRepo,
                remoteOwnedSync: NoopOwnedSync()
            )
        )
        let seed = SeedCatalogueUseCase(
            source: NoopCatalogueSource(),
            repository: cardRepo
        )
        let sut = PriceSyncViewModel(
            useCase: useCase,
            seedCatalogue: seed,
            cardRepository: cardRepo,
            reachability: reach
        )
        return (sut, itemRepo, priceRepo, backend, reach)
    }

    private func addOwned(_ cardID: UUID, to itemRepo: SwiftDataCollectionItemRepository) async throws {
        try await itemRepo.save(CollectionItem(cardID: cardID, stackID: UUID()))
    }

    @Test("No Wi-Fi → status .waitingForWiFi + alert flag flipped on")
    func wifiGate() async throws {
        let (sut, _, _, _, reach) = try makeSUT()
        reach.isOnWiFi = false

        await sut.sync()

        #expect(sut.status == .waitingForWiFi)
        #expect(sut.isWiFiAlertPresented)
    }

    @Test("No owned cards → status .failed with no-owned-cards message")
    func noOwnedFailure() async throws {
        let (sut, _, _, _, _) = try makeSUT()
        await sut.sync()
        if case .failed(let message) = sut.status {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected .failed status, got \(sut.status)")
        }
    }

    @Test("Happy path → status .finished + count, snapshots persisted")
    func happyPath() async throws {
        let (sut, itemRepo, priceRepo, backend, _) = try makeSUT()
        let cardID = UUID()
        try await addOwned(cardID, to: itemRepo)
        backend.queued = .success([
            PriceSnapshot(
                cardID: cardID, source: .cardkingdom, date: Date(),
                currency: .usd, retail: 1.5
            )
        ])

        await sut.sync()

        if case .finished(let count) = sut.status {
            #expect(count == 1)
        } else {
            Issue.record("Expected .finished, got \(sut.status)")
        }
        #expect(try await priceRepo.latest(cardID: cardID, source: .cardkingdom) != nil)
        #expect(priceRepo.lastSyncedAt != nil)
    }

    @Test("Backend failure → status .failed, no timestamp stamped")
    func sourceFailurePath() async throws {
        struct DummyError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let (sut, itemRepo, priceRepo, backend, _) = try makeSUT()
        try await addOwned(UUID(), to: itemRepo)
        backend.queued = .failure(DummyError())

        await sut.sync()

        if case .failed = sut.status {
            // ok
        } else {
            Issue.record("Expected .failed, got \(sut.status)")
        }
        #expect(priceRepo.lastSyncedAt == nil)
    }
}

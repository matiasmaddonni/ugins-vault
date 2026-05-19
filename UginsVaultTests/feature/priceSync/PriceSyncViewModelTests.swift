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

    final class InMemoryStorage: SessionStorageDataSource, @unchecked Sendable {
        private var bag: [String: String] = [:]
        func string(forKey key: String) -> String? { bag[key] }
        func set(_ value: String?, forKey key: String) {
            if let value { bag[key] = value } else { bag.removeValue(forKey: key) }
        }
    }

    /// Spins up a full real-stack VM with in-memory SwiftData containers
    /// for both Card + Price, plus a fake source we control.
    private func makeSUT() throws -> (
        PriceSyncViewModel,
        SwiftDataCardRepository,
        SwiftDataPriceRepository,
        StubSource,
        StubReachability
    ) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self, SwiftDataPriceSnapshot.self,
            configurations: config
        )
        let cardRepo = SwiftDataCardRepository(modelContainer: container)
        let priceRepo = SwiftDataPriceRepository(
            modelContainer: container,
            lastSyncStorage: InMemoryStorage()
        )
        let source = StubSource()
        let reach = StubReachability()
        let useCase = SyncPricesUseCase(
            priceRepository: priceRepo,
            cardRepository: cardRepo,
            priceSource: source
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
        return (sut, cardRepo, priceRepo, source, reach)
    }

    /// Returns an empty catalogue page — used by the seed step so
    /// the tests don't hit the real Scryfall API.
    final class NoopCatalogueSource: CardCatalogueSource, @unchecked Sendable {
        func fetchCards(query: String, page: Int) async throws -> CardCataloguePage {
            CardCataloguePage(cards: [], hasMore: false)
        }
    }

    private func makeCard(id: UUID = UUID()) -> Card {
        Card(
            id: id,
            oracleID: UUID(),
            name: "Test",
            typeLine: "Instant",
            setCode: "tst",
            setName: "Test Set",
            collectorNumber: "1"
        )
    }

    @Test("No Wi-Fi → status .waitingForWiFi + alert flag flipped on")
    func wifiGate() async throws {
        let (sut, _, _, _, reach) = try makeSUT()
        reach.isOnWiFi = false

        await sut.sync()

        #expect(sut.status == .waitingForWiFi)
        #expect(sut.isWiFiAlertPresented)
    }

    @Test("Empty catalogue → status .failed with no-owned-cards message")
    func emptyCatalogueFailure() async throws {
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
        let (sut, cardRepo, priceRepo, source, _) = try makeSUT()
        let card = makeCard()
        try await cardRepo.save([card])
        source.queued = .success([
            PriceSnapshot(
                cardID: card.id, source: .cardkingdom, date: Date(),
                currency: .usd, retail: 1.5
            )
        ])

        await sut.sync()

        if case .finished(let count) = sut.status {
            #expect(count == 1)
        } else {
            Issue.record("Expected .finished, got \(sut.status)")
        }
        #expect(try await priceRepo.latest(cardID: card.id, source: .cardkingdom) != nil)
        #expect(priceRepo.lastSyncedAt != nil)
    }

    @Test("Source failure → status .failed, no timestamp stamped")
    func sourceFailurePath() async throws {
        struct DummyError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let (sut, cardRepo, priceRepo, source, _) = try makeSUT()
        try await cardRepo.save([makeCard()])
        source.queued = .failure(DummyError())

        await sut.sync()

        if case .failed = sut.status {
            // ok
        } else {
            Issue.record("Expected .failed, got \(sut.status)")
        }
        #expect(priceRepo.lastSyncedAt == nil)
    }
}

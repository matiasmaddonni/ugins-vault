//
//  RealDashboardRepositoryTests.swift
//  UginsVaultTests — Data / Dashboard
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("RealDashboardRepository")
@MainActor
struct RealDashboardRepositoryTests {

    private struct Stack5 {
        let cardRepo: SwiftDataCardRepository
        let itemRepo: SwiftDataCollectionItemRepository
        let stackRepo: SwiftDataStackRepository
        let priceRepo: SwiftDataPriceRepository
        let wishRepo: SwiftDataWishlistRepository
        let session: MockSessionRepository
        let sut: RealDashboardRepository
    }

    private func makeStack() throws -> Stack5 {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self, SwiftDataStack.self, SwiftDataCollectionItem.self,
            SwiftDataPriceSnapshot.self, SwiftDataWishlistItem.self,
            configurations: config
        )
        let cardRepo = SwiftDataCardRepository(modelContainer: container)
        let itemRepo = SwiftDataCollectionItemRepository(modelContainer: container)
        let stackRepo = SwiftDataStackRepository(modelContainer: container)
        let priceRepo = SwiftDataPriceRepository(modelContainer: container, lastSyncStorage: MockSessionStorage())
        let wishRepo = SwiftDataWishlistRepository(modelContainer: container)
        let session = MockSessionRepository() // preferredPriceSource = .cardkingdom
        let sut = RealDashboardRepository(
            cardRepository: cardRepo,
            collectionItemRepository: itemRepo,
            stackRepository: stackRepo,
            priceRepository: priceRepo,
            sessionRepository: session,
            wishlistRepository: wishRepo
        )
        return Stack5(cardRepo: cardRepo, itemRepo: itemRepo, stackRepo: stackRepo,
                      priceRepo: priceRepo, wishRepo: wishRepo, session: session, sut: sut)
    }

    private func card(_ id: UUID, set: String = "fdn") -> Card {
        Card(id: id, oracleID: UUID(), name: "Test", typeLine: "Instant",
             setCode: set, setName: set.uppercased(), collectorNumber: "1")
    }

    @Test("fetch computes total value + stats from owned cards × prices")
    func computesStatsAndValue() async throws {
        let env = try makeStack()
        let stack = Stack(id: UUID(), name: "Burn", kind: .deck, format: .modern, colors: [.red])
        try await env.stackRepo.save(stack)

        let cardID = UUID()
        try await env.cardRepo.save([card(cardID)])
        try await env.itemRepo.save(CollectionItem(cardID: cardID, stackID: stack.id, quantity: 2))

        let day = Date()
        try await env.priceRepo.upsert(
            [PriceSnapshot(cardID: cardID, source: .cardkingdom, date: day, currency: .usd, retail: 5)],
            keepingSince: day.addingTimeInterval(-100_000)
        )

        let snapshot = try await env.sut.fetch()

        #expect(snapshot.stats.totalCards == 2)
        #expect(snapshot.stats.uniqueCards == 1)
        #expect(snapshot.totalValueUSD == 10)            // 5 × 2
        #expect(snapshot.byFormat.contains { $0.valueUSD == 10 })
    }

    @Test("fetch yields zero stats for an empty collection")
    func emptyCollection() async throws {
        let env = try makeStack()

        let snapshot = try await env.sut.fetch()

        #expect(snapshot.stats.totalCards == 0)
        #expect(snapshot.stats.uniqueCards == 0)
        #expect(snapshot.totalValueUSD == 0)
    }

    @Test("unpriced owned cards contribute quantity but no value")
    func unpricedContributesNoValue() async throws {
        let env = try makeStack()
        let stack = Stack(id: UUID(), name: "Box", kind: .binder, format: nil, colors: [])
        try await env.stackRepo.save(stack)

        let cardID = UUID()
        try await env.cardRepo.save([card(cardID)])
        try await env.itemRepo.save(CollectionItem(cardID: cardID, stackID: stack.id, quantity: 3))
        // no price snapshot

        let snapshot = try await env.sut.fetch()

        #expect(snapshot.stats.totalCards == 3)
        #expect(snapshot.totalValueUSD == 0)
    }

    @Test("multi-day price history drives week-delta, sparkline + movers")
    func computesHistory() async throws {
        let env = try makeStack()
        let stack = Stack(id: UUID(), name: "Burn", kind: .deck, format: .modern, colors: [.red])
        try await env.stackRepo.save(stack)

        let cardID = UUID()
        try await env.cardRepo.save([card(cardID)])
        try await env.itemRepo.save(CollectionItem(cardID: cardID, stackID: stack.id, quantity: 1))

        let calendar = Calendar(identifier: .iso8601)
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        try await env.priceRepo.upsert([
            PriceSnapshot(cardID: cardID, source: .cardkingdom, date: weekAgo, currency: .usd, retail: 10),
            PriceSnapshot(cardID: cardID, source: .cardkingdom, date: today, currency: .usd, retail: 12)
        ], keepingSince: weekAgo.addingTimeInterval(-100_000))

        let snapshot = try await env.sut.fetch()

        #expect(snapshot.weekDeltaUSD == 2)              // 12 − 10, qty 1
        #expect(snapshot.monthSparkline.isEmpty == false)
        #expect(snapshot.gainers.contains { $0.id == cardID.uuidString })
    }
}

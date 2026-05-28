//
//  SwiftDataPriceRepositoryTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SwiftDataPriceRepository")
@MainActor
struct SwiftDataPriceRepositoryTests {

    // MARK: - Helpers

    private final class InMemoryStorage: SessionStorageDataSource, @unchecked Sendable {
        private var bag: [String: String] = [:]
        func string(forKey key: String) -> String? { bag[key] }
        func set(_ value: String?, forKey key: String) {
            if let value { bag[key] = value } else { bag.removeValue(forKey: key) }
        }
    }

    private func makeRepo() throws -> (SwiftDataPriceRepository, InMemoryStorage) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataPriceSnapshot.self,
            configurations: config
        )
        let storage = InMemoryStorage()
        let repo = SwiftDataPriceRepository(modelContainer: container, lastSyncStorage: storage)
        return (repo, storage)
    }

    private func snapshot(
        cardID: UUID = UUID(),
        source: PriceSource = .cardkingdom,
        date: Date = Date(),
        currency: Currency = .usd,
        retail: Decimal = 1.0
    ) -> PriceSnapshot {
        PriceSnapshot(cardID: cardID, source: source, date: date, currency: currency, retail: retail)
    }

    // MARK: - Tests

    @Test("upsert inserts new rows + latest returns the freshest")
    func upsertInsertsAndLatest() async throws {
        let (repo, _) = try makeRepo()
        let card = UUID()
        let now = Date()
        let yesterday = now.addingTimeInterval(-86_400)

        try await repo.upsert(
            [
                snapshot(cardID: card, source: .cardkingdom, date: yesterday, retail: 4.0),
                snapshot(cardID: card, source: .cardkingdom, date: now,       retail: 5.0)
            ],
            keepingSince: yesterday.addingTimeInterval(-1)
        )

        let latest = try await repo.latest(cardID: card, source: .cardkingdom)
        #expect(latest?.retail == Decimal(5.0))
    }

    @Test("upsert collapses duplicates on (cardID, source, day)")
    func upsertDeduplicates() async throws {
        let (repo, _) = try makeRepo()
        let card = UUID()
        let day = Date()
        try await repo.upsert(
            [
                snapshot(cardID: card, source: .tcgplayer, date: day, retail: 1.0),
                snapshot(cardID: card, source: .tcgplayer, date: day, retail: 9.0)
            ],
            keepingSince: day.addingTimeInterval(-1)
        )
        let history = try await repo.history(
            cardID: card,
            source: .tcgplayer,
            since: day.addingTimeInterval(-1)
        )
        #expect(history.count == 1)
        #expect(history.first?.retail == Decimal(9.0))
    }

    @Test("upsert prunes rows older than the cutoff")
    func upsertPrunes() async throws {
        let (repo, _) = try makeRepo()
        let card = UUID()
        let oldDate = Date().addingTimeInterval(-100 * 86_400)
        let recent = Date()
        try await repo.upsert(
            [snapshot(cardID: card, source: .cardkingdom, date: oldDate, retail: 0.5)],
            keepingSince: oldDate.addingTimeInterval(-1)
        )
        try await repo.upsert(
            [snapshot(cardID: card, source: .cardkingdom, date: recent, retail: 1.5)],
            keepingSince: recent.addingTimeInterval(-30 * 86_400)
        )
        let history = try await repo.history(
            cardID: card,
            source: .cardkingdom,
            since: Date.distantPast
        )
        #expect(history.count == 1)
        #expect(history.first?.retail == Decimal(1.5))
    }

    @Test("markSyncCompleted persists across re-instantiation")
    func syncTimestampSurvivesRestart() async throws {
        let (repo, storage) = try makeRepo()
        #expect(try await repo.lastSyncedAt() == nil)

        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        try await repo.markSyncCompleted(at: stamp)
        #expect(try await repo.lastSyncedAt() == stamp)

        // Build a fresh repo over the same storage — should rehydrate.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataPriceSnapshot.self, configurations: config)
        let restarted = SwiftDataPriceRepository(modelContainer: container, lastSyncStorage: storage)
        #expect(try await restarted.lastSyncedAt() == stamp)
    }

    @Test("deleteAll wipes data + clears the sync timestamp")
    func deleteAllResets() async throws {
        let (repo, _) = try makeRepo()
        let card = UUID()
        try await repo.upsert(
            [snapshot(cardID: card)],
            keepingSince: Date.distantPast
        )
        try await repo.markSyncCompleted(at: Date())

        try await repo.deleteAll()

        #expect(try await repo.lastSyncedAt() == nil)
        #expect(try await repo.latest(cardID: card, source: .cardkingdom) == nil)
    }
}

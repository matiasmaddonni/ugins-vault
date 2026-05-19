//
//  SwiftDataCardRepositoryTests.swift
//  UginsVaultTests — Data / SwiftData
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SwiftDataCardRepository")
@MainActor
struct SwiftDataCardRepositoryTests {

    // MARK: - Helpers

    private func makeRepository() throws -> SwiftDataCardRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCard.self, configurations: config)
        return SwiftDataCardRepository(modelContainer: container)
    }

    private func makeBolt(name: String = "Lightning Bolt") -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            oracleText: "Deal 3 damage to any target.",
            manaCost: "{R}",
            cmc: 1,
            colors: [.red],
            colorIdentity: [.red],
            rarity: .common,
            setCode: "lea",
            setName: "Limited Edition Alpha",
            collectorNumber: "161",
            finishes: [.nonfoil],
            prices: CardPrices(usd: Decimal(string: "20.00"))
        )
    }

    // MARK: - Tests

    @Test("totalCount starts at zero")
    func emptyStart() async throws {
        let repo = try makeRepository()
        let count = try await repo.totalCount()
        #expect(count == 0)
    }

    @Test("save inserts new rows and updates the in-memory cards slice on refresh")
    func saveInserts() async throws {
        let repo = try makeRepository()
        let bolt = makeBolt()

        try await repo.save([bolt])
        let loaded = try await repo.refresh(query: "")

        #expect(try await repo.totalCount() == 1)
        #expect(loaded.first?.name == "Lightning Bolt")
        #expect(repo.cards.count == 1)
    }

    @Test("save is idempotent by id (updates existing row instead of duplicating)")
    func saveIsIdempotent() async throws {
        let repo = try makeRepository()
        let bolt = makeBolt()

        try await repo.save([bolt])
        // Save the same id with a tweaked field — should update, not duplicate.
        let updated = Card(
            id: bolt.id,
            oracleID: bolt.oracleID,
            name: "Lightning Bolt (Reprint)",
            typeLine: bolt.typeLine,
            setCode: bolt.setCode,
            setName: bolt.setName,
            collectorNumber: bolt.collectorNumber
        )
        try await repo.save([updated])

        #expect(try await repo.totalCount() == 1)
        #expect((try await repo.card(id: bolt.id))?.name == "Lightning Bolt (Reprint)")
    }

    @Test("refresh filters by case-insensitive substring on the name")
    func refreshFiltersByName() async throws {
        let repo = try makeRepository()
        try await repo.save([
            makeBolt(name: "Lightning Bolt"),
            makeBolt(name: "Lightning Helix"),
            makeBolt(name: "Counterspell")
        ])

        let bolts = try await repo.refresh(query: "lightning")

        #expect(bolts.count == 2)
        #expect(bolts.allSatisfy { $0.name.lowercased().contains("lightning") })
    }

    @Test("deleteAll wipes the catalogue")
    func deleteAllWipes() async throws {
        let repo = try makeRepository()
        try await repo.save([makeBolt(), makeBolt(name: "Counterspell")])
        #expect(try await repo.totalCount() == 2)

        try await repo.deleteAll()

        #expect(try await repo.totalCount() == 0)
        #expect(repo.cards.isEmpty)
    }

    @Test("Mapper round-trips colours, finishes, prices, and images")
    func mapperRoundTrips() async throws {
        let repo = try makeRepository()
        let card = Card(
            id: UUID(),
            oracleID: UUID(),
            name: "Brainstorm",
            typeLine: "Instant",
            manaCost: "{U}",
            cmc: 1,
            colors: [.blue],
            colorIdentity: [.blue],
            rarity: .common,
            setCode: "ice",
            setName: "Ice Age",
            collectorNumber: "61",
            finishes: [.nonfoil, .foil],
            images: CardImages(
                small: URL(string: "https://example.com/small.jpg"),
                normal: URL(string: "https://example.com/normal.jpg")
            ),
            prices: CardPrices(usd: Decimal(string: "3.50"), usdFoil: Decimal(string: "12.00"))
        )

        try await repo.save([card])
        let loaded = try await repo.card(id: card.id)

        #expect(loaded?.colors == [.blue])
        #expect(loaded?.finishes == [.nonfoil, .foil])
        #expect(loaded?.images.normal?.absoluteString == "https://example.com/normal.jpg")
        #expect(loaded?.prices.usd == Decimal(string: "3.50"))
        #expect(loaded?.prices.usdFoil == Decimal(string: "12.00"))
    }
}

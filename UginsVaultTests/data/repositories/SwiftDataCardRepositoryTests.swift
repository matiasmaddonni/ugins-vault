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
        let loaded = try await repo.refresh(.recent)

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

        let bolts = try await repo.refresh(CardQuery(text: "lightning"))

        #expect(bolts.count == 2)
        #expect(bolts.allSatisfy { $0.name.lowercased().contains("lightning") })
    }

    @Test("delete(id:) removes a single card by Scryfall printing id")
    func deleteByIdRemovesSingleRow() async throws {
        let repo = try makeRepository()
        let bolt = makeBolt()
        let counterspell = makeBolt(name: "Counterspell")
        try await repo.save([bolt, counterspell])
        #expect(try await repo.totalCount() == 2)

        try await repo.delete(id: bolt.id)

        #expect(try await repo.totalCount() == 1)
        #expect(try await repo.card(id: bolt.id) == nil)
        #expect(try await repo.card(id: counterspell.id) != nil)
    }

    @Test("delete(id:) with an unknown id is a no-op")
    func deleteUnknownIdNoOp() async throws {
        let repo = try makeRepository()
        try await repo.save([makeBolt()])
        let randomID = UUID()

        try await repo.delete(id: randomID)

        #expect(try await repo.totalCount() == 1)
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

    // MARK: - Sort + filter + pagination

    @Test("Sort by name returns ascending")
    func sortByName() async throws {
        let repo = try makeRepository()
        try await repo.save([
            makeBolt(name: "Counterspell"),
            makeBolt(name: "Ancestral Recall"),
            makeBolt(name: "Brainstorm")
        ])

        let loaded = try await repo.refresh(CardQuery(sort: .nameAscending))

        #expect(loaded.map(\.name) == ["Ancestral Recall", "Brainstorm", "Counterspell"])
    }

    @Test("Sort by price descending puts highest first, nil last")
    func sortByPrice() async throws {
        let repo = try makeRepository()
        try await repo.save([
            cardWithPrice(name: "Mid", usd: Decimal(string: "5.00")),
            cardWithPrice(name: "High", usd: Decimal(string: "20.00")),
            cardWithPrice(name: "None", usd: nil)
        ])

        let loaded = try await repo.refresh(CardQuery(sort: .priceDescending))

        #expect(loaded.first?.name == "High")
        #expect(loaded.last?.name == "None")
    }

    @Test("Filter by rarity restricts results")
    func filterByRarity() async throws {
        let repo = try makeRepository()
        try await repo.save([
            cardWithRarity(name: "C", rarity: .common),
            cardWithRarity(name: "M", rarity: .mythic),
            cardWithRarity(name: "R", rarity: .rare)
        ])

        let loaded = try await repo.refresh(
            CardQuery(filter: CardFilter(rarities: [.mythic, .rare]))
        )

        #expect(loaded.count == 2)
        #expect(loaded.allSatisfy { [.mythic, .rare].contains($0.rarity) })
    }

    @Test("Filter by colour requires all selected colours")
    func filterByColor() async throws {
        let repo = try makeRepository()
        try await repo.save([
            cardWithColors(name: "Mono Red", colors: [.red]),
            cardWithColors(name: "Boros", colors: [.red, .white]),
            cardWithColors(name: "Mono Blue", colors: [.blue])
        ])

        let loaded = try await repo.refresh(
            CardQuery(filter: CardFilter(colors: [.red]))
        )

        #expect(loaded.count == 2)
        #expect(loaded.map(\.name).sorted() == ["Boros", "Mono Red"])
    }

    @Test("Pagination respects offset + limit")
    func paginationOffsetLimit() async throws {
        let repo = try makeRepository()
        try await repo.save((0..<10).map { makeBolt(name: String(format: "Card %02d", $0)) })

        let firstPage = try await repo.refresh(CardQuery(offset: 0, limit: 4))
        let secondPage = try await repo.refresh(CardQuery(offset: 4, limit: 4))

        #expect(firstPage.count == 4)
        #expect(secondPage.count == 4)
        #expect(firstPage.first?.name == "Card 00")
        #expect(secondPage.first?.name == "Card 04")
    }

    @Test("count(matching:) reports the unpaginated total")
    func countMatching() async throws {
        let repo = try makeRepository()
        try await repo.save([
            cardWithRarity(name: "A", rarity: .common),
            cardWithRarity(name: "B", rarity: .common),
            cardWithRarity(name: "C", rarity: .rare)
        ])

        let commons = try await repo.count(matching: CardQuery(filter: CardFilter(rarities: [.common])))
        let all = try await repo.count(matching: .recent)

        #expect(commons == 2)
        #expect(all == 3)
    }

    @Test("availableSetCodes returns unique sorted set codes")
    func availableSetCodes() async throws {
        let repo = try makeRepository()
        try await repo.save([
            cardWithSet(name: "A", set: "lea"),
            cardWithSet(name: "B", set: "lea"),
            cardWithSet(name: "C", set: "ice"),
            cardWithSet(name: "D", set: "fdn")
        ])

        let codes = try await repo.availableSetCodes()

        #expect(codes == ["fdn", "ice", "lea"])
    }

    // MARK: - Helpers continued

    private func cardWithPrice(name: String, usd: Decimal?) -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            setCode: "tst",
            setName: "Test",
            collectorNumber: "1",
            prices: CardPrices(usd: usd)
        )
    }

    private func cardWithRarity(name: String, rarity: Rarity) -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            rarity: rarity,
            setCode: "tst",
            setName: "Test",
            collectorNumber: "1"
        )
    }

    private func cardWithColors(name: String, colors: Set<ManaColor>) -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            colors: colors,
            colorIdentity: colors,
            setCode: "tst",
            setName: "Test",
            collectorNumber: "1"
        )
    }

    private func cardWithSet(name: String, set: String) -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            setCode: set,
            setName: set.uppercased(),
            collectorNumber: "1"
        )
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

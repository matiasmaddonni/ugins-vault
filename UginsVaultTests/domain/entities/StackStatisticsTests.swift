//
//  StackStatisticsTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import Testing
@testable import UginsVault

@Suite("StackStatistics")
struct StackStatisticsTests {

    // MARK: - Fixtures

    private func card(
        _ id: UUID,
        name: String = "Card",
        colors: Set<ManaColor> = [],
        rarity: Rarity = .common,
        cmc: Double = 1,
        type: String = "Creature"
    ) -> Card {
        Card(
            id: id,
            oracleID: UUID(),
            name: name,
            typeLine: type,
            cmc: cmc,
            colors: colors,
            rarity: rarity,
            setCode: "tst",
            setName: "Test Set",
            collectorNumber: "1",
            images: CardImages(small: URL(string: "https://x/\(name).jpg"))
        )
    }

    private func item(_ cardID: UUID, qty: Int = 1) -> CollectionItem {
        CollectionItem(cardID: cardID, stackID: UUID(), quantity: qty)
    }

    private func intCount(_ slices: [FormatSlice], _ id: String) -> Int {
        guard let s = slices.first(where: { $0.id == id }) else { return 0 }
        return NSDecimalNumber(decimal: s.valueUSD).intValue
    }

    // MARK: - Tests

    @Test("empty items yields .empty")
    func emptyItems() {
        let stats = StackStatistics.make(items: [], cardsByID: [:], priceMap: [:])
        #expect(stats == .empty)
        #expect(stats.isEmpty)
    }

    @Test("total value sums price × quantity; pricedFraction reflects coverage")
    func totalsAndCoverage() {
        let a = UUID(), b = UUID()
        let items = [item(a, qty: 2), item(b, qty: 1)]
        let cards = [a: card(a), b: card(b)]
        // Only `a` is priced.
        let stats = StackStatistics.make(items: items, cardsByID: cards, priceMap: [a: 3])
        #expect(stats.totalValueUSD == 6)        // 3 × 2
        #expect(stats.cardCount == 3)            // 2 + 1
        #expect(stats.uniqueCount == 2)
        #expect(abs(stats.pricedFraction - (2.0 / 3.0)) < 0.0001)
    }

    @Test("colour buckets: mono, multicolour, colourless")
    func colorBuckets() {
        let mono = UUID(), multi = UUID(), none = UUID()
        let items = [item(mono, qty: 2), item(multi), item(none)]
        let cards = [
            mono: card(mono, colors: [.red]),
            multi: card(multi, colors: [.red, .green]),
            none: card(none, colors: [], type: "Artifact")
        ]
        let stats = StackStatistics.make(items: items, cardsByID: cards, priceMap: [:])
        #expect(intCount(stats.byColor, "color_red") == 2)
        #expect(intCount(stats.byColor, "color_multicolor") == 1)
        #expect(intCount(stats.byColor, "color_colorless") == 1)
        #expect(stats.byColor.contains { $0.id == "color_blue" } == false)
    }

    @Test("rarity buckets fold special/bonus/unknown into Other")
    func rarityBuckets() {
        let r = UUID(), s = UUID()
        let items = [item(r), item(s)]
        let cards = [r: card(r, rarity: .mythic), s: card(s, rarity: .special)]
        let stats = StackStatistics.make(items: items, cardsByID: cards, priceMap: [:])
        #expect(intCount(stats.byRarity, "rarity_mythic") == 1)
        #expect(intCount(stats.byRarity, "rarity_other") == 1)
    }

    @Test("mana curve excludes lands and caps at the 7+ bucket")
    func manaCurve() {
        let land = UUID(), big = UUID(), one = UUID()
        let items = [item(land), item(big), item(one, qty: 3)]
        let cards = [
            land: card(land, cmc: 0, type: "Basic Land — Mountain"),
            big: card(big, cmc: 8, type: "Creature"),
            one: card(one, cmc: 1, type: "Instant")
        ]
        let stats = StackStatistics.make(items: items, cardsByID: cards, priceMap: [:])
        func bucket(_ id: Int) -> Int { stats.manaCurve.first { $0.id == id }?.count ?? -1 }
        #expect(bucket(0) == 0)        // land excluded
        #expect(bucket(1) == 3)
        #expect(bucket(7) == 1)        // cmc 8 -> "7+"
        #expect(stats.manaCurve.first { $0.id == 7 }?.label == "7+")
    }

    @Test("top cards: priced only, sorted by line value, capped")
    func topCards() {
        let cheap = UUID(), pricey = UUID(), free = UUID()
        let items = [item(cheap, qty: 1), item(pricey, qty: 2), item(free)]
        let cards = [
            cheap: card(cheap, name: "Cheap"),
            pricey: card(pricey, name: "Pricey"),
            free: card(free, name: "Free")
        ]
        // free has no price -> excluded
        let stats = StackStatistics.make(
            items: items, cardsByID: cards,
            priceMap: [cheap: 5, pricey: 4], topCount: 5
        )
        #expect(stats.topCards.count == 2)
        #expect(stats.topCards.first?.name == "Pricey")   // 4 × 2 = 8 > 5
        #expect(stats.topCards.first?.lineValueUSD == 8)
        #expect(stats.topCards.contains { $0.name == "Free" } == false)
    }

    @Test("commander is surfaced and still included in the total")
    func commanderSurfaced() {
        let cmd = UUID(), other = UUID()
        let items = [item(cmd, qty: 1), item(other, qty: 1)]
        let cards = [
            cmd: card(cmd, name: "Atraxa", colors: [.white, .blue, .black, .green], rarity: .mythic),
            other: card(other, name: "Sol Ring")
        ]
        let stats = StackStatistics.make(
            items: items, cardsByID: cards,
            priceMap: [cmd: 12, other: 3], commanderCardID: cmd
        )
        #expect(stats.commander?.name == "Atraxa")
        #expect(stats.commander?.lineValueUSD == 12)
        // Commander value is part of the stack total, not separate.
        #expect(stats.totalValueUSD == 15)
        #expect(intCount(stats.byColor, "color_multicolor") == 1)
    }

    @Test("commander is nil when none is pinned")
    func commanderAbsent() {
        let a = UUID()
        let stats = StackStatistics.make(
            items: [item(a)], cardsByID: [a: card(a)], priceMap: [a: 1]
        )
        #expect(stats.commander == nil)
    }

    @Test("topCount caps the list")
    func topCountCap() {
        var items: [CollectionItem] = []
        var cards: [UUID: Card] = [:]
        var prices: [UUID: Decimal] = [:]
        for i in 0..<10 {
            let id = UUID()
            items.append(item(id))
            cards[id] = card(id, name: "C\(i)")
            prices[id] = Decimal(i + 1)
        }
        let stats = StackStatistics.make(items: items, cardsByID: cards, priceMap: prices, topCount: 3)
        #expect(stats.topCards.count == 3)
        #expect(stats.topCards.first?.unitValueUSD == 10)   // highest price
    }
}

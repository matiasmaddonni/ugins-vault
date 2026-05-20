//
//  APIPriceCatalogueSourceMappingTests.swift
//  UginsVaultTests — Data / Backend
//

import Foundation
import Testing
@testable import UginsVault

@Suite("APIPriceCatalogueSource mapping")
struct APIPriceCatalogueSourceMappingTests {

    private func response(
        cardId: String,
        source: String = "tcgplayer",
        currency: String = "USD",
        history: [(String, Decimal)]
    ) -> PricesResponseDTO {
        PricesResponseDTO(
            source: source,
            window: 35,
            cards: [
                PriceCardDTO(
                    cardId: cardId,
                    source: source,
                    currency: currency,
                    current: history.last?.1,
                    history: history.map { PricePointDTO(date: $0.0, price: $0.1) }
                )
            ]
        )
    }

    @Test("maps each history point to a snapshot for allowed cards")
    func mapsAllowed() {
        let id = UUID()
        let dto = response(cardId: id.uuidString.lowercased(), history: [("2026-04-15", 10), ("2026-04-16", 11)])

        let snaps = APIPriceCatalogueSource.map(dto, allowList: [id])

        #expect(snaps.count == 2)
        #expect(snaps.allSatisfy { $0.cardID == id && $0.source == .tcgplayer && $0.currency == .usd })
        #expect(Set(snaps.map(\.retail)) == [10, 11])
    }

    @Test("drops cards outside the allow-list")
    func dropsDisallowed() {
        let id = UUID()
        let other = UUID()
        let dto = response(cardId: id.uuidString, history: [("2026-04-15", 10)])

        #expect(APIPriceCatalogueSource.map(dto, allowList: [other]).isEmpty)
    }

    @Test("drops non-positive prices and unparseable dates")
    func dropsBadPoints() {
        let id = UUID()
        let dto = response(cardId: id.uuidString, history: [("2026-04-15", 0), ("nope", 5), ("2026-04-17", 7)])

        let snaps = APIPriceCatalogueSource.map(dto, allowList: [id])

        #expect(snaps.count == 1)
        #expect(snaps.first?.retail == 7)
    }

    @Test("day parses yyyy-MM-dd at UTC midnight")
    func dayParsing() throws {
        let day = try #require(APIPriceCatalogueSource.day(from: "2026-04-15"))
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: day)
        #expect(comps.year == 2026)
        #expect(comps.month == 4)
        #expect(comps.day == 15)
        #expect(comps.hour == 0)
        #expect(comps.minute == 0)
    }

    @Test("invalid day string returns nil")
    func invalidDay() {
        #expect(APIPriceCatalogueSource.day(from: "2026/04/15") == nil)
        #expect(APIPriceCatalogueSource.day(from: "") == nil)
    }
}

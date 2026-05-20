//
//  LatestPriceUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import Testing
@testable import UginsVault

@Suite("LatestPriceUseCase")
@MainActor
struct LatestPriceUseCaseTests {

    private func makeCard() -> Card {
        Card(id: UUID(), oracleID: UUID(), name: "Test", typeLine: "Instant",
             setCode: "tst", setName: "Test", collectorNumber: "1")
    }

    private func snap(_ cardID: UUID, _ source: PriceSource, _ retail: Decimal) -> PriceSnapshot {
        PriceSnapshot(cardID: cardID, source: source, date: Date(), currency: source.nativeCurrency, retail: retail)
    }

    @Test("prefers the preferred source")
    func prefersPreferred() async {
        let card = makeCard()
        let repo = MockPriceRepository()
        repo.latestBySource = [
            .tcgplayer: snap(card.id, .tcgplayer, 5),
            .cardkingdom: snap(card.id, .cardkingdom, 9)
        ]
        let sut = LatestPriceUseCase(priceRepository: repo)

        let resolved = await sut.execute(card: card, preferred: .tcgplayer)

        #expect(resolved?.amount == 5)
        #expect(resolved?.source == .marketplace(.tcgplayer))
    }

    @Test("falls back to another source when the preferred has none")
    func fallsBack() async {
        let card = makeCard()
        let repo = MockPriceRepository()
        repo.latestBySource = [.cardmarket: snap(card.id, .cardmarket, 7)]
        let sut = LatestPriceUseCase(priceRepository: repo)

        let resolved = await sut.execute(card: card, preferred: .tcgplayer)

        #expect(resolved?.amount == 7)
        #expect(resolved?.source == .marketplace(.cardmarket))
    }

    @Test("returns nil when nothing is priced")
    func noneReturnsNil() async {
        let repo = MockPriceRepository()
        let sut = LatestPriceUseCase(priceRepository: repo)

        let resolved = await sut.execute(card: makeCard(), preferred: .tcgplayer)

        #expect(resolved == nil)
    }

    @Test("skips non-positive prices")
    func skipsZero() async {
        let card = makeCard()
        let repo = MockPriceRepository()
        repo.latestBySource = [.tcgplayer: snap(card.id, .tcgplayer, 0)]
        let sut = LatestPriceUseCase(priceRepository: repo)

        let resolved = await sut.execute(card: card, preferred: .tcgplayer)

        #expect(resolved == nil)
    }
}

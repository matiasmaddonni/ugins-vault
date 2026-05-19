//
//  MockDashboardRepository.swift
//  UginsVault — Data layer / Dashboard
//
//  Returns the seed values from the HTML prototype's
//  `UVData.dashboard`. v0.4 ships with this; a real repository
//  reading from CardRepository / CollectionItemRepository /
//  StackRepository can replace it once pricing-history is wired in
//  by swapping the binding in `DependencyContainer`.
//

import Foundation
import Observation

@MainActor
@Observable
public final class MockDashboardRepository: DashboardRepository {

    public private(set) var snapshot: DashboardSnapshot?
    public private(set) var isFetching: Bool = false

    public init() {}

    @discardableResult
    public func fetch() async throws -> DashboardSnapshot {
        isFetching = true
        defer { isFetching = false }

        let assembled = DashboardSnapshot.assemble(
            realStats: .init(),
            mockedHistory: Self.seed
        )
        self.snapshot = assembled
        return assembled
    }

    // MARK: - Seed
    //
    // Seeded from the HTML prototype's `UVData.dashboard`. Bumping any
    // value here changes both the loaded screen and the screenshots
    // used in marketing / acceptance review — keep in sync if those
    // are ever regenerated.

    public static let seed: DashboardSnapshot.MockedHistory = .init(
        totalValueUSD: Decimal(string: "4287.50")!,
        weekDeltaUSD: Decimal(string: "184.30")!,
        weekDeltaPct: 4.5,
        monthSparkline: [
            3920, 3865, 3890, 3940, 3978, 4012, 4055, 4032,
            4070, 4108, 4145, 4178, 4150, 4192, 4220, 4198, 4240, 4287
        ].map { Decimal($0) },
        gainers: [
            Mover(id: "sheoldred",   name: "Sheoldred, the Apocalypse",   setCode: "DMU", deltaUSD: Decimal(string:  "7.40")!, pct:  10.3),
            Mover(id: "bowmasters",  name: "Orcish Bowmasters",           setCode: "LTR", deltaUSD: Decimal(string:  "6.80")!, pct:  16.8),
            Mover(id: "ragavan",     name: "Ragavan, Nimble Pilferer",    setCode: "MH2", deltaUSD: Decimal(string:  "5.40")!, pct:   8.7),
            Mover(id: "one-ring",    name: "The One Ring",                setCode: "LTR", deltaUSD: Decimal(string:  "4.20")!, pct:   8.0),
            Mover(id: "wrenn-six",   name: "Wrenn and Six",               setCode: "MH1", deltaUSD: Decimal(string:  "3.10")!, pct:   4.1)
        ],
        losers: [
            Mover(id: "solitude",    name: "Solitude",                    setCode: "MH2", deltaUSD: Decimal(string: "-3.10")!, pct:  -4.6),
            Mover(id: "fow",         name: "Force of Will",               setCode: "2X2", deltaUSD: Decimal(string: "-2.50")!, pct:  -2.7),
            Mover(id: "karn",        name: "Karn, the Great Creator",     setCode: "WAR", deltaUSD: Decimal(string: "-1.20")!, pct:  -3.4),
            Mover(id: "fable",       name: "Fable of the Mirror-Breaker", setCode: "NEO", deltaUSD: Decimal(string: "-0.40")!, pct:  -1.6),
            Mover(id: "verdant",     name: "Verdant Catacombs",           setCode: "MM3", deltaUSD: Decimal(string: "-0.30")!, pct:  -0.7)
        ],
        byFormat: [
            FormatSlice(id: "modern",    displayName: "Modern",    valueUSD: 1840, colorHex: 0xB9A4D6),
            FormatSlice(id: "commander", displayName: "Commander", valueUSD: 1120, colorHex: 0xC9A24B),
            FormatSlice(id: "legacy",    displayName: "Legacy",    valueUSD:  760, colorHex: 0x6BA8D8),
            FormatSlice(id: "pioneer",   displayName: "Pioneer",   valueUSD:  380, colorHex: 0x7BC58F),
            FormatSlice(id: "pauper",    displayName: "Pauper",    valueUSD:  187, colorHex: 0x7E7A93)
        ],
        bySet: [
            SetBar(code: "MH2", name: "Modern Horizons 2",      valueUSD: 712),
            SetBar(code: "LTR", name: "LotR: Tales",            valueUSD: 418),
            SetBar(code: "MH1", name: "Modern Horizons",        valueUSD: 362),
            SetBar(code: "WAR", name: "War of the Spark",       valueUSD: 284),
            SetBar(code: "NEO", name: "Kamigawa: Neon Dynasty", valueUSD: 210),
            SetBar(code: "DMU", name: "Dominaria United",       valueUSD: 158)
        ],
        stats: .init(
            totalCards: 1248,
            uniqueCards: 487,
            foils: 32,
            avgValueUSD: Decimal(string: "3.44")!
        ),
        wishlistTrackedCount: 5,
        wishlistReadyToBuyCount: 1
    )
}

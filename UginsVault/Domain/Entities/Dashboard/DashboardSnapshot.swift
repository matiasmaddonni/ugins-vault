//
//  DashboardSnapshot.swift
//  UginsVault — Domain layer / Dashboard
//
//  Aggregate value type the Dashboard view binds to. Bundles every
//  number the screen renders so the view layer reads one source of
//  truth + the VM exposes a single `snapshot` property.
//
//  Assembly path: `DashboardSnapshot.assemble(realStats:mockedHistory:)`
//  is the *one* place the real-stats values (from the local repos)
//  meet the mocked historical values (sparkline / deltas / movers).
//  When pricing history lands, the call site swaps the mocked bag for
//  a real one — every other Dashboard call site stays untouched.
//

import Foundation

public struct DashboardSnapshot: Equatable, Sendable {

    public let totalValueUSD: Decimal
    public let weekDeltaUSD: Decimal      // signed
    public let weekDeltaPct: Double       // signed
    public let monthSparkline: [Decimal]  // ~18–30 points, oldest first
    public let gainers: [Mover]           // top 5, descending by pct
    public let losers: [Mover]            // top 5, ascending by pct
    public let byFormat: [FormatSlice]
    public let bySet: [SetBar]
    public let stats: CollectionStats
    public let wishlistTrackedCount: Int
    public let wishlistReadyToBuyCount: Int

    public init(
        totalValueUSD: Decimal,
        weekDeltaUSD: Decimal,
        weekDeltaPct: Double,
        monthSparkline: [Decimal],
        gainers: [Mover],
        losers: [Mover],
        byFormat: [FormatSlice],
        bySet: [SetBar],
        stats: CollectionStats,
        wishlistTrackedCount: Int,
        wishlistReadyToBuyCount: Int
    ) {
        self.totalValueUSD = totalValueUSD
        self.weekDeltaUSD = weekDeltaUSD
        self.weekDeltaPct = weekDeltaPct
        self.monthSparkline = monthSparkline
        self.gainers = gainers
        self.losers = losers
        self.byFormat = byFormat
        self.bySet = bySet
        self.stats = stats
        self.wishlistTrackedCount = wishlistTrackedCount
        self.wishlistReadyToBuyCount = wishlistReadyToBuyCount
    }
}

// MARK: - Assembly

extension DashboardSnapshot {

    /// Bundle of values computable from the user's actual catalogue +
    /// stacks. When something here is `nil` the assembler falls back
    /// to whichever stub the mock bag supplies.
    public struct RealStats: Equatable, Sendable {
        public var totalValueUSD: Decimal?
        public var byFormat: [FormatSlice]?
        public var bySet: [SetBar]?
        public var stats: CollectionStats?

        public init(
            totalValueUSD: Decimal? = nil,
            byFormat: [FormatSlice]? = nil,
            bySet: [SetBar]? = nil,
            stats: CollectionStats? = nil
        ) {
            self.totalValueUSD = totalValueUSD
            self.byFormat      = byFormat
            self.bySet         = bySet
            self.stats         = stats
        }
    }

    /// Bundle of values that NEED price history we don't yet have.
    /// HISTORICAL_MOCK — flip this entire struct to a real producer
    /// when an FX/price-history backend lands.
    public struct MockedHistory: Equatable, Sendable {
        public let totalValueUSD: Decimal
        public let weekDeltaUSD: Decimal
        public let weekDeltaPct: Double
        public let monthSparkline: [Decimal]
        public let gainers: [Mover]
        public let losers: [Mover]
        public let byFormat: [FormatSlice]
        public let bySet: [SetBar]
        public let stats: CollectionStats
        public let wishlistTrackedCount: Int
        public let wishlistReadyToBuyCount: Int

        public init(
            totalValueUSD: Decimal,
            weekDeltaUSD: Decimal,
            weekDeltaPct: Double,
            monthSparkline: [Decimal],
            gainers: [Mover],
            losers: [Mover],
            byFormat: [FormatSlice],
            bySet: [SetBar],
            stats: CollectionStats,
            wishlistTrackedCount: Int,
            wishlistReadyToBuyCount: Int
        ) {
            self.totalValueUSD = totalValueUSD
            self.weekDeltaUSD = weekDeltaUSD
            self.weekDeltaPct = weekDeltaPct
            self.monthSparkline = monthSparkline
            self.gainers = gainers
            self.losers = losers
            self.byFormat = byFormat
            self.bySet = bySet
            self.stats = stats
            self.wishlistTrackedCount = wishlistTrackedCount
            self.wishlistReadyToBuyCount = wishlistReadyToBuyCount
        }
    }

    /// Single point where real catalogue stats meet mocked history.
    /// Pass `RealStats()` when no real data is available — the snapshot
    /// degrades cleanly to the mock bag.
    public static func assemble(
        realStats: RealStats,
        mockedHistory: MockedHistory
    ) -> DashboardSnapshot {
        DashboardSnapshot(
            totalValueUSD:           realStats.totalValueUSD ?? mockedHistory.totalValueUSD,
            weekDeltaUSD:            mockedHistory.weekDeltaUSD,
            weekDeltaPct:            mockedHistory.weekDeltaPct,
            monthSparkline:          mockedHistory.monthSparkline,
            gainers:                 mockedHistory.gainers,
            losers:                  mockedHistory.losers,
            byFormat:                realStats.byFormat ?? mockedHistory.byFormat,
            bySet:                   realStats.bySet ?? mockedHistory.bySet,
            stats:                   realStats.stats ?? mockedHistory.stats,
            wishlistTrackedCount:    mockedHistory.wishlistTrackedCount,
            wishlistReadyToBuyCount: mockedHistory.wishlistReadyToBuyCount
        )
    }
}

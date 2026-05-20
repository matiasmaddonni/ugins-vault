//
//  DashboardSnapshotAssembleTests.swift
//  UginsVaultTests — Dashboard
//
//  Guards the real-vs-mock merge contract. The "stop showing mocked
//  movers" fix relies on real history fields (even empty arrays)
//  overriding the seed bag — these tests pin that behaviour.
//

import Foundation
import Testing
@testable import UginsVault

@Suite("DashboardSnapshot.assemble")
@MainActor
struct DashboardSnapshotAssembleTests {

    @Test("Empty RealStats falls back to the mocked history bag")
    func emptyRealStatsUsesMock() {
        let snapshot = DashboardSnapshot.assemble(
            realStats: .init(),
            mockedHistory: MockDashboardRepository.seed
        )
        #expect(snapshot.gainers.count == MockDashboardRepository.seed.gainers.count)
        #expect(snapshot.totalValueUSD == MockDashboardRepository.seed.totalValueUSD)
        #expect(snapshot.wishlistTrackedCount == MockDashboardRepository.seed.wishlistTrackedCount)
    }

    @Test("Real history fields override the mock — empty movers win")
    func realOverridesMock() {
        let real = DashboardSnapshot.RealStats(
            totalValueUSD: Decimal(10),
            wishlistTrackedCount: 3,
            wishlistReadyToBuyCount: 0,
            weekDeltaUSD: Decimal(2),
            weekDeltaPct: 25.0,
            monthSparkline: [Decimal(8), Decimal(10)],
            gainers: [],
            losers: []
        )
        let snapshot = DashboardSnapshot.assemble(
            realStats: real,
            mockedHistory: MockDashboardRepository.seed
        )

        #expect(snapshot.gainers.isEmpty)
        #expect(snapshot.losers.isEmpty)
        #expect(snapshot.weekDeltaUSD == Decimal(2))
        #expect(snapshot.weekDeltaPct == 25.0)
        #expect(snapshot.monthSparkline == [Decimal(8), Decimal(10)])
        #expect(snapshot.totalValueUSD == Decimal(10))
        #expect(snapshot.wishlistTrackedCount == 3)
        #expect(snapshot.wishlistReadyToBuyCount == 0)
    }
}

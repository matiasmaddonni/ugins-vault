//
//  MockDashboardRepositoryTests.swift
//  UginsVaultTests
//

import Foundation
import Testing
@testable import UginsVault

@Suite("MockDashboardRepository")
@MainActor
struct MockDashboardRepositoryTests {

    @Test("fetch returns the seed snapshot")
    func fetchReturnsSeed() async throws {
        let repo = MockDashboardRepository()
        let snapshot = try await repo.fetch()

        #expect(snapshot.totalValueUSD == Decimal(string: "4287.50"))
        #expect(snapshot.weekDeltaPct == 4.5)
        #expect(snapshot.gainers.count == 5)
        #expect(snapshot.losers.count == 5)
        #expect(snapshot.byFormat.count == 5)
        #expect(snapshot.bySet.count == 6)
        #expect(snapshot.stats.totalCards == 1248)
    }

    @Test("snapshot property is bumped on every fetch")
    func fetchPopulatesSnapshotProperty() async throws {
        let repo = MockDashboardRepository()
        #expect(repo.snapshot == nil)
        _ = try await repo.fetch()
        #expect(repo.snapshot != nil)
    }

    @Test("assemble honours RealStats overrides for the by-format / by-set / stats / total")
    func assembleRespectsRealStats() {
        let real = DashboardSnapshot.RealStats(
            totalValueUSD: 9999,
            byFormat: [],
            bySet: [],
            stats: .zero
        )
        let assembled = DashboardSnapshot.assemble(
            realStats: real,
            mockedHistory: MockDashboardRepository.seed
        )

        #expect(assembled.totalValueUSD == 9999)
        #expect(assembled.byFormat.isEmpty)
        #expect(assembled.bySet.isEmpty)
        #expect(assembled.stats == .zero)
        // Mocked-only fields stay from the mock bag.
        #expect(assembled.gainers.count == 5)
        #expect(assembled.weekDeltaPct == 4.5)
    }

    @Test("assemble falls back to the mock bag when RealStats fields are nil")
    func assembleFallsBack() {
        let assembled = DashboardSnapshot.assemble(
            realStats: .init(),
            mockedHistory: MockDashboardRepository.seed
        )

        #expect(assembled.totalValueUSD == Decimal(string: "4287.50"))
        #expect(assembled.byFormat.count == 5)
        #expect(assembled.stats.totalCards == 1248)
    }
}

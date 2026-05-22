//
//  CollectionViewModelTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("CollectionViewModel")
@MainActor
struct CollectionViewModelTests {

    // MARK: - Helpers

    final class InMemoryStorage: SessionStorageDataSource, @unchecked Sendable {
        private var bag: [String: String] = [:]
        func string(forKey key: String) -> String? { bag[key] }
        func set(_ value: String?, forKey key: String) {
            if let value { bag[key] = value } else { bag.removeValue(forKey: key) }
        }
    }

    private func makeRepos() throws -> (SwiftDataCardRepository, SwiftDataPriceRepository) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self, SwiftDataPriceSnapshot.self,
            configurations: config
        )
        return (
            SwiftDataCardRepository(modelContainer: container),
            SwiftDataPriceRepository(modelContainer: container, lastSyncStorage: InMemoryStorage())
        )
    }

    private func makeCard(name: String) -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            setCode: "fdn",
            setName: "Foundations",
            collectorNumber: "1"
        )
    }

    private func makeSUT(
        sessionCurrency: Currency = .usd
    ) throws -> (CollectionViewModel, SwiftDataCardRepository, SwiftDataPriceRepository, MockSessionRepository) {
        let session = MockSessionRepository()
        session.currency = sessionCurrency
        let (repo, priceRepo) = try makeRepos()
        let vm = CollectionViewModel(
            sessionRepository: session,
            cardRepository: repo,
            priceRepository: priceRepo
        )
        return (vm, repo, priceRepo, session)
    }

    // MARK: - Tests

    @Test("Init reads the currency preference from the session repository")
    func initReadsCurrency() throws {
        let (sut, _, _, _) = try makeSUT(sessionCurrency: .eur)
        #expect(sut.currency == .eur)
    }

    @Test("Defaults: empty cards, zero count, idle status")
    func defaultsAreEmpty() throws {
        let (sut, _, _, _) = try makeSUT()
        #expect(sut.cards.isEmpty)
        #expect(sut.matchingCount == 0)
        #expect(sut.searchQuery == "")
        #expect(sut.status == .idle)
    }

    @Test("loadOrSeed pulls existing cards when the repo isn't empty")
    func loadsExistingCards() async throws {
        let (sut, repo, _, _) = try makeSUT()
        try await repo.save([makeCard(name: "Bolt"), makeCard(name: "Counterspell")])

        await sut.loadOrSeed()

        #expect(sut.cards.count == 2)
        #expect(sut.matchingCount == 2)
        #expect(sut.status == .idle)
    }

    @Test("loadOrSeed does NOT auto-seed — Collection starts empty")
    func emptyCatalogueStaysEmpty() async throws {
        let (sut, _, _, _) = try makeSUT()

        await sut.loadOrSeed()

        #expect(sut.cards.isEmpty)
        #expect(sut.status == .idle)
    }

    @Test("search filters cards by query through the repository")
    func searchFilters() async throws {
        let (sut, repo, _, _) = try makeSUT()
        try await repo.save([
            makeCard(name: "Lightning Bolt"),
            makeCard(name: "Lightning Helix"),
            makeCard(name: "Brainstorm")
        ])
        await sut.loadOrSeed()

        sut.searchQuery = "lightning"
        await sut.search()
        try await Task.sleep(for: .milliseconds(400))

        #expect(sut.cards.count == 2)
        #expect(sut.cards.allSatisfy { $0.name.lowercased().contains("lightning") })
    }

    @Test("totalValueUSD sums priced cards from the local store")
    func totalValueSums() async throws {
        let (sut, repo, priceRepo, _) = try makeSUT()
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")
        try await repo.save([a, b])

        let day = Date()
        try await priceRepo.upsert([
            PriceSnapshot(cardID: a.id, source: .cardkingdom, date: day, currency: .usd, retail: Decimal(string: "1.50")!),
            PriceSnapshot(cardID: b.id, source: .cardkingdom, date: day, currency: .usd, retail: Decimal(string: "1.50")!)
        ], keepingSince: day.addingTimeInterval(-100_000))

        await sut.loadOrSeed()

        #expect(sut.totalValueUSD == Decimal(string: "3.00"))
    }

    @Test("setSort updates sort + reruns the search")
    func setSortReorders() async throws {
        let (sut, repo, _, _) = try makeSUT()
        try await repo.save([
            makeCard(name: "Counterspell"),
            makeCard(name: "Ancestral Recall")
        ])
        await sut.loadOrSeed()

        sut.setSort(.nameAscending)
        try await Task.sleep(for: .milliseconds(400))

        #expect(sut.sort == .nameAscending)
        #expect(sut.cards.first?.name == "Ancestral Recall")
    }

    @Test("applyFilter narrows the result set + advertises hasActiveFilter")
    func applyFilterNarrows() async throws {
        let (sut, repo, _, _) = try makeSUT()
        try await repo.save([
            makeCard(name: "A"),
            makeCard(name: "B"),
            makeCard(name: "C")
        ])
        await sut.loadOrSeed()

        sut.applyFilter(CardFilter(sets: ["fdn"]))
        try await Task.sleep(for: .milliseconds(400))

        #expect(sut.hasActiveFilter == true)
        #expect(sut.cards.count == 3)
    }

    @Test("removeCard(id:) deletes from repo + drops the row + updates count")
    func removeCardPulls() async throws {
        let (sut, repo, _, _) = try makeSUT()
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")
        try await repo.save([a, b])
        await sut.loadOrSeed()
        #expect(sut.cards.count == 2)
        #expect(sut.matchingCount == 2)

        await sut.removeCard(id: a.id)

        #expect(sut.cards.count == 1)
        #expect(sut.cards.first?.id == b.id)
        #expect(sut.matchingCount == 1)
    }

    @Test("loadMoreIfNeeded appends the next page until hasMore is false")
    func paginationLoadsMore() async throws {
        let session = MockSessionRepository()
        let (repo, priceRepo) = try makeRepos()
        let cards = (0..<10).map { makeCard(name: String(format: "Card %02d", $0)) }
        try await repo.save(cards)

        let sut = CollectionViewModel(
            sessionRepository: session,
            cardRepository: repo,
            priceRepository: priceRepo,
            pageSize: 4
        )

        await sut.loadOrSeed()
        #expect(sut.cards.count == 4)
        #expect(sut.hasMore == true)

        await sut.loadMoreIfNeeded()
        #expect(sut.cards.count == 8)

        await sut.loadMoreIfNeeded()
        #expect(sut.cards.count == 10)
        #expect(sut.hasMore == false)
    }

    // MARK: - Price status polling

    private struct StubPriceStatusSource: PriceStatusSource {
        let result: PriceStatus
        func status() async throws -> PriceStatus { result }
    }

    @Test("polling marks unpriced, non-noData cards as fetching")
    func pollingMarksFetching() async throws {
        let session = MockSessionRepository()
        let (repo, priceRepo) = try makeRepos()
        let a = makeCard(name: "A")
        let b = makeCard(name: "B")
        try await repo.save([a, b])

        let day = Date()
        try await priceRepo.upsert(
            [PriceSnapshot(cardID: a.id, source: .cardkingdom, date: day, currency: .usd, retail: Decimal(1))],
            keepingSince: day.addingTimeInterval(-100_000)
        )

        let status = StubPriceStatusSource(result: PriceStatus(pending: [b.id], noData: [], updatedAt: nil))
        let sut = CollectionViewModel(
            sessionRepository: session,
            cardRepository: repo,
            priceRepository: priceRepo,
            priceStatusSource: status
        )

        await sut.onAppear()
        try await Task.sleep(for: .milliseconds(150))

        #expect(sut.isFetchingPrice(b.id))
        #expect(!sut.isFetchingPrice(a.id))
        sut.stopPriceStatusPolling()
    }
}

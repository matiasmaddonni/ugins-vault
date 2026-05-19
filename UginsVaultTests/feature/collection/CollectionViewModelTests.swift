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

    private func makeRepo() throws -> SwiftDataCardRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCard.self, configurations: config)
        return SwiftDataCardRepository(modelContainer: container)
    }

    private func makeCard(name: String) -> Card {
        Card(
            id: UUID(),
            oracleID: UUID(),
            name: name,
            typeLine: "Instant",
            setCode: "fdn",
            setName: "Foundations",
            collectorNumber: "1",
            prices: CardPrices(usd: Decimal(string: "1.50"))
        )
    }

    private func makeSUT(
        sessionCurrency: Currency = .usd,
        seedPages: [CardCataloguePage] = []
    ) throws -> (CollectionViewModel, SwiftDataCardRepository, MockSessionRepository, MockCardCatalogueSource) {
        let session = MockSessionRepository()
        session.currency = sessionCurrency
        let repo = try makeRepo()
        let source = MockCardCatalogueSource()
        source.queuedPages = seedPages
        let useCase = SeedCatalogueUseCase(source: source, repository: repo)
        let vm = CollectionViewModel(
            sessionRepository: session,
            cardRepository: repo,
            seedCatalogue: useCase,
            seedQuery: "set:test"
        )
        return (vm, repo, session, source)
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
        let (sut, repo, _, source) = try makeSUT()
        try await repo.save([makeCard(name: "Bolt"), makeCard(name: "Counterspell")])

        await sut.loadOrSeed()

        #expect(sut.cards.count == 2)
        #expect(sut.matchingCount == 2)
        #expect(source.fetchCallCount == 0)
        #expect(sut.status == .idle)
    }

    @Test("loadOrSeed seeds an empty catalogue via the SeedCatalogue use case")
    func seedsEmptyCatalogue() async throws {
        let (sut, _, _, source) = try makeSUT(
            seedPages: [
                CardCataloguePage(cards: [makeCard(name: "A"), makeCard(name: "B")], hasMore: false)
            ]
        )

        await sut.loadOrSeed()

        #expect(source.fetchCallCount == 1)
        #expect(source.lastQuery == "set:test")
        #expect(sut.cards.count == 2)
        #expect(sut.matchingCount == 2)
        #expect(sut.status == .idle)
    }

    @Test("loadOrSeed surfaces seeding errors as .error status")
    func errorOnSeedFailure() async throws {
        let (sut, _, _, source) = try makeSUT()
        source.nextError = ScryfallError.transport(underlying: URLError(.notConnectedToInternet))

        await sut.loadOrSeed()

        guard case .error = sut.status else {
            Issue.record("Expected .error, got \(sut.status)")
            return
        }
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

        #expect(sut.cards.count == 2)
        #expect(sut.cards.allSatisfy { $0.name.lowercased().contains("lightning") })
    }

    @Test("totalValueUSD sums non-foil USD prices across loaded cards")
    func totalValueSums() async throws {
        let (sut, repo, _, _) = try makeSUT()
        try await repo.save([
            makeCard(name: "A"),
            makeCard(name: "B")
        ])
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
        try await Task.sleep(for: .milliseconds(50))

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
        try await Task.sleep(for: .milliseconds(50))

        #expect(sut.hasActiveFilter == true)
        #expect(sut.cards.count == 3)
    }

    @Test("loadMoreIfNeeded appends the next page until hasMore is false")
    func paginationLoadsMore() async throws {
        let session = MockSessionRepository()
        let repo = try makeRepo()
        let cards = (0..<10).map { makeCard(name: String(format: "Card %02d", $0)) }
        try await repo.save(cards)

        let useCase = SeedCatalogueUseCase(
            source: MockCardCatalogueSource(),
            repository: repo
        )
        let sut = CollectionViewModel(
            sessionRepository: session,
            cardRepository: repo,
            seedCatalogue: useCase,
            seedQuery: "set:test",
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
}

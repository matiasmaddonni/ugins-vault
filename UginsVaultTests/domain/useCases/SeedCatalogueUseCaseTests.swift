//
//  SeedCatalogueUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SeedCatalogueUseCase")
@MainActor
struct SeedCatalogueUseCaseTests {

    // MARK: - Helpers

    private func makeRepository() throws -> SwiftDataCardRepository {
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
            collectorNumber: "1"
        )
    }

    // MARK: - Tests

    @Test("Saves a single non-paginated result")
    func savesSinglePage() async throws {
        let source = MockCardCatalogueSource()
        source.queuedPages = [
            CardCataloguePage(cards: [makeCard(name: "Bolt"), makeCard(name: "Counterspell")], hasMore: false)
        ]
        let repo = try makeRepository()
        let sut = SeedCatalogueUseCase(source: source, repository: repo)

        let saved = try await sut.execute(query: "set:fdn")

        #expect(saved == 2)
        #expect(try await repo.totalCount() == 2)
        #expect(source.fetchCallCount == 1)
    }

    @Test("Paginates while hasMore is true")
    func paginatesAcrossPages() async throws {
        let source = MockCardCatalogueSource()
        source.queuedPages = [
            CardCataloguePage(cards: [makeCard(name: "A"), makeCard(name: "B")], hasMore: true),
            CardCataloguePage(cards: [makeCard(name: "C")], hasMore: false)
        ]
        let repo = try makeRepository()
        let sut = SeedCatalogueUseCase(source: source, repository: repo)

        let saved = try await sut.execute(query: "set:fdn")

        #expect(saved == 3)
        #expect(source.fetchCallCount == 2)
        #expect(source.lastPage == 2)
    }

    @Test("Stops at maxPages even if hasMore is still true")
    func respectsMaxPages() async throws {
        let source = MockCardCatalogueSource()
        source.queuedPages = [
            CardCataloguePage(cards: [makeCard(name: "A")], hasMore: true),
            CardCataloguePage(cards: [makeCard(name: "B")], hasMore: true),
            CardCataloguePage(cards: [makeCard(name: "C")], hasMore: true)
        ]
        let repo = try makeRepository()
        let sut = SeedCatalogueUseCase(source: source, repository: repo)

        let saved = try await sut.execute(query: "set:fdn", maxPages: 2)

        #expect(saved == 2)
        #expect(source.fetchCallCount == 2)
    }

    @Test("Treats a 404 'not_found' on page > 1 as end-of-list")
    func notFoundEndsPagination() async throws {
        let source = MockCardCatalogueSource()
        source.queuedPages = [
            CardCataloguePage(cards: [makeCard(name: "A")], hasMore: true)
        ]
        // Second page will throw a 404.
        // We can't queue an error after the first success in this mock,
        // so simulate by injecting after the first call via the progress
        // callback isn't possible — instead, prime the error before the
        // second call by checking call count.
        let repo = try makeRepository()
        let sut = SeedCatalogueUseCase(source: source, repository: repo)

        // Inject the error via a side trigger: after first fetch we'll
        // arrange the mock to throw on next.
        var progressCount = 0
        let saved = try await sut.execute(query: "set:fdn") { _ in
            if progressCount == 0 {
                source.nextError = ScryfallError.apiError(
                    status: 404,
                    envelope: .init(status: 404, code: "not_found", details: "no more pages", warnings: nil, type: nil)
                )
            }
            progressCount += 1
        }

        #expect(saved == 1)
        #expect(source.fetchCallCount == 2)
    }

    @Test("Re-throws non-not_found errors")
    func rethrowsRealErrors() async throws {
        let source = MockCardCatalogueSource()
        source.nextError = ScryfallError.transport(underlying: URLError(.notConnectedToInternet))
        let repo = try makeRepository()
        let sut = SeedCatalogueUseCase(source: source, repository: repo)

        do {
            _ = try await sut.execute(query: "set:fdn")
            Issue.record("Expected transport error to bubble up")
        } catch {
            guard case ScryfallError.transport = error else {
                Issue.record("Expected ScryfallError.transport, got \(error)")
                return
            }
        }
    }

    @Test("Progress callback fires once per page")
    func progressFiresPerPage() async throws {
        let source = MockCardCatalogueSource()
        source.queuedPages = [
            CardCataloguePage(cards: [makeCard(name: "A")], hasMore: true),
            CardCataloguePage(cards: [makeCard(name: "B")], hasMore: false)
        ]
        let repo = try makeRepository()
        let sut = SeedCatalogueUseCase(source: source, repository: repo)

        var progressUpdates: [SeedCatalogueUseCase.Progress] = []
        _ = try await sut.execute(query: "set:fdn") { progress in
            progressUpdates.append(progress)
        }

        #expect(progressUpdates.count == 2)
        #expect(progressUpdates.last?.isFinished == true)
    }
}
